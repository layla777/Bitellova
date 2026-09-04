//
//  main.swift
//
//
//  Created by ideguti masaya on 2026/09/01.
//

import Bitellova
import BitellovaAI

@inline(never)
func playOneGame() throws {
    var game = Game()

    while !game.isGameOver {
        if game.isPass {
            try game.pass()
            continue
        }

        let moves = game.legalMoves
        let move =
            UInt64(1)
            << (63 - moves.leadingZeroBitCount)

        try game.play(move)
    }
}

func profileGames(trialCount: Int) throws {
    let clock = ContinuousClock()
    let start = clock.now

    for _ in 0..<trialCount {
        try playOneGame()
    }

    let elapsed = start.duration(to: clock.now)

    print("\(trialCount) games")
    print("Elapsed:", elapsed)
    print("Average:", elapsed / trialCount)
}

@inline(never)
func profileMonteCarloPlayouts(
    gameCount: Int
) throws {
    precondition(gameCount > 0)

    let initialGame = Game()
    let randomPlayout = RandomPlayout()

    var generator =
        SplitMix64(seed: 42)

    var blackWins = 0
    var whiteWins = 0
    var draws = 0

    let clock = ContinuousClock()
    let start = clock.now

    for _ in 0..<gameCount {
        let outcome =
            try randomPlayout.outcome(
                from: initialGame,
                using: &generator
            )

        switch outcome {
        case .blackWin:
            blackWins += 1

        case .whiteWin:
            whiteWins += 1

        case .draw:
            draws += 1
        }
    }

    let elapsed =
        start.duration(to: clock.now)

    print(
        "\(gameCount) Monte Carlo random playouts"
    )
    print("Seed:", 42)
    print("Black wins:", blackWins)
    print("White wins:", whiteWins)
    print("Draws:", draws)
    print("Elapsed:", elapsed)
    print(
        "Average:",
        elapsed / gameCount
    )
}

@inline(never)
func profileMonteCarloSelections(
    trialCount: Int,
    playoutsPerMove: Int
) throws {
    precondition(trialCount > 0)
    precondition(playoutsPerMove > 0)

    let game = Game()

    let player =
        MonteCarloPlayer(
            playoutsPerMove:
                playoutsPerMove
        )

    var generator =
        SplitMix64(seed: 42)

    var checksum: UInt64 = 0

    let clock = ContinuousClock()
    let start = clock.now

    for _ in 0..<trialCount {
        let move =
            try player.selectMove(
                in: game,
                using: &generator
            )

        checksum &+= move
    }

    let elapsed =
        start.duration(to: clock.now)

    print(
        "\(trialCount) Monte Carlo move selections"
    )
    print(
        "Playouts per legal move:",
        playoutsPerMove
    )
    print("Seed:", 42)
    print("Elapsed:", elapsed)
    print(
        "Average:",
        elapsed / trialCount
    )
    print(
        "Checksum:",
        String(checksum, radix: 16)
    )
}

@inline(never)
func transformAllSymmetries(
    _ bits: UInt64
) -> UInt64 {
    var checksum: UInt64 = 0

    checksum &+=
        BoardSymmetry.identity.transform(bits)

    checksum &+=
        BoardSymmetry.rotate90Clockwise.transform(bits)

    checksum &+=
        BoardSymmetry.rotate180.transform(bits)

    checksum &+=
        BoardSymmetry.rotate270Clockwise.transform(bits)

    checksum &+=
        BoardSymmetry.flipLeftRight.transform(bits)

    checksum &+=
        BoardSymmetry.flipTopBottom.transform(bits)

    checksum &+=
        BoardSymmetry.reflectMainDiagonal.transform(bits)

    checksum &+=
        BoardSymmetry.reflectAntiDiagonal.transform(bits)

    return checksum
}

@inline(never)
func playOneMCTSGame<
    R: RandomNumberGenerator
>(
    with player: MCTSPlayer,
    using generator: inout R
) throws -> (
    outcome: Game.Outcome,
    moves: [UInt64]
) {
    var game = Game()
    var moves: [UInt64] = []
    moves.reserveCapacity(60)

    while !game.isGameOver {
        if game.isPass {
            try game.pass()
            continue
        }

        let move =
            try player.selectMove(
                in: game,
                using: &generator
            )

        try game.play(move)
        moves.append(move)
    }

    guard let outcome = game.outcome else {
        preconditionFailure(
            "MCTS self-play did not produce an outcome"
        )
    }

    return (outcome, moves)
}

func profileMCTSGames(
    gameCount: Int,
    iterationCount: Int
) throws {
    precondition(gameCount > 0)
    precondition(iterationCount > 0)

    let player = MCTSPlayer(
        iterationCount: iterationCount
    )

    var generator =
        SplitMix64(seed: 42)

    var blackWins = 0
    var whiteWins = 0
    var draws = 0

    var gameMoves: [[UInt64]] = []
    gameMoves.reserveCapacity(gameCount)

    let clock = ContinuousClock()
    let start = clock.now

    for _ in 0..<gameCount {
        let result =
            try playOneMCTSGame(
                with: player,
                using: &generator
            )

        gameMoves.append(result.moves)

        switch result.outcome {
        case .blackWin:
            blackWins += 1

        case .whiteWin:
            whiteWins += 1

        case .draw:
            draws += 1
        }
    }

    let elapsed =
        start.duration(to: clock.now)

    print(
        "\(gameCount) MCTS self-play games"
    )
    print(
        "Iterations per move:",
        iterationCount
    )
    print("Black wins:", blackWins)
    print("White wins:", whiteWins)
    print("Draws:", draws)
    print("Elapsed:", elapsed)
    print(
        "Average:",
        elapsed / gameCount
    )

    for (index, moves) in gameMoves.enumerated() {
        let transcript =
            try moves
            .map { try Board.square($0) }
            .joined()

        print(
            "Game \(index + 1):",
            transcript
        )
    }
}

func profileSymmetries(iterations: Int) {
    precondition(iterations > 0)

    var state: UInt64 =
        0x8123_4567_89AB_CDEF

    var checksum: UInt64 = 0

    let clock = ContinuousClock()
    let start = clock.now

    for _ in 0..<iterations {
        state =
            state
            &* 6_364_136_223_846_793_005
            &+ 1_442_695_040_888_963_407

        checksum &+=
            transformAllSymmetries(state)
    }

    let elapsed = start.duration(to: clock.now)

    let transformCount =
        iterations
        * BoardSymmetry.allCases.count

    print("\(transformCount) symmetry transforms")
    print("Elapsed:", elapsed)
    print(
        "Average:",
        elapsed / transformCount
    )
    print(
        "Checksum:",
        String(checksum, radix: 16)
    )
}

@inline(never)
func playMCTSAgainstRandom<
    MCTSGenerator: RandomNumberGenerator,
    RandomGenerator: RandomNumberGenerator
>(
    mctsColor: Player,
    mctsPlayer: MCTSPlayer,
    randomPlayer: RandomPlayer,
    using mctsGenerator:
        inout MCTSGenerator,
    randomGenerator:
        inout RandomGenerator
) throws -> Game.Outcome {
    var game = Game()

    while !game.isGameOver {
        if game.isPass {
            try game.pass()
            continue
        }

        let move: UInt64

        if game.currentPlayer == mctsColor {
            move =
                try mctsPlayer.selectMove(
                    in: game,
                    using: &mctsGenerator
                )
        } else {
            let legalMoves =
                game.legalMoves

            move =
                randomPlayer.selectMove(
                    from: legalMoves,
                    using: &randomGenerator
                )
        }

        try game.play(move)
    }

    guard let outcome = game.outcome else {
        preconditionFailure(
            "MCTS versus Random game produced no outcome"
        )
    }

    return outcome
}

func profileMCTSAgainstRandom(
    gameCount: Int,
    iterationCount: Int
) throws {
    precondition(gameCount > 0)
    precondition(iterationCount > 0)

    let mctsPlayer = MCTSPlayer(
        iterationCount: iterationCount
    )

    let randomPlayer =
        RandomPlayer()

    var mctsGenerator =
        SplitMix64(seed: 42)

    var randomGenerator =
        SplitMix64(seed: 43)

    var mctsWins = 0
    var randomWins = 0
    var draws = 0

    var mctsWinsAsBlack = 0
    var mctsWinsAsWhite = 0

    let clock = ContinuousClock()
    let start = clock.now

    for gameIndex in 0..<gameCount {
        let mctsColor: Player =
            gameIndex.isMultiple(of: 2)
            ? .black
            : .white

        let outcome =
            try playMCTSAgainstRandom(
                mctsColor: mctsColor,
                mctsPlayer: mctsPlayer,
                randomPlayer: randomPlayer,
                using: &mctsGenerator,
                randomGenerator:
                    &randomGenerator
            )

        switch outcome {
        case .draw:
            draws += 1

        case .blackWin:
            if mctsColor == .black {
                mctsWins += 1
                mctsWinsAsBlack += 1
            } else {
                randomWins += 1
            }

        case .whiteWin:
            if mctsColor == .white {
                mctsWins += 1
                mctsWinsAsWhite += 1
            } else {
                randomWins += 1
            }
        }
    }

    let elapsed =
        start.duration(to: clock.now)

    let mctsScore =
        (Double(mctsWins)
            + Double(draws) * 0.5)
        / Double(gameCount)

    print(
        "\(gameCount) MCTS versus Random games"
    )
    print(
        "MCTS iterations per move:",
        iterationCount
    )
    print("MCTS wins:", mctsWins)
    print("Random wins:", randomWins)
    print("Draws:", draws)
    print(
        "MCTS wins as Black:",
        mctsWinsAsBlack
    )
    print(
        "MCTS wins as White:",
        mctsWinsAsWhite
    )
    print("MCTS score rate:", mctsScore)
    print("Elapsed:", elapsed)
    print(
        "Average:",
        elapsed / gameCount
    )
}

@inline(never)
func playMCTSAgainstMonteCarlo<
    MCTSGenerator: RandomNumberGenerator,
    MonteCarloGenerator: RandomNumberGenerator
>(
    mctsColor: Player,
    mctsPlayer: MCTSPlayer,
    monteCarloPlayer: MonteCarloPlayer,
    using mctsGenerator:
        inout MCTSGenerator,
    monteCarloGenerator:
        inout MonteCarloGenerator
) throws -> Game.Outcome {
    var game = Game()

    while !game.isGameOver {
        if game.isPass {
            try game.pass()
            continue
        }

        let move: UInt64

        if game.currentPlayer == mctsColor {
            move =
                try mctsPlayer.selectMove(
                    in: game,
                    using: &mctsGenerator
                )
        } else {
            move =
                try monteCarloPlayer.selectMove(
                    in: game,
                    using:
                        &monteCarloGenerator
                )
        }

        try game.play(move)
    }

    guard let outcome = game.outcome else {
        preconditionFailure(
            "MCTS versus Monte Carlo game produced no outcome"
        )
    }

    return outcome
}

func profileMCTSAgainstMonteCarlo(
    gameCount: Int,
    mctsIterationCount: Int,
    playoutsPerMove: Int
) throws {
    precondition(gameCount > 0)
    precondition(mctsIterationCount > 0)
    precondition(playoutsPerMove > 0)

    let mctsPlayer = MCTSPlayer(
        iterationCount:
            mctsIterationCount
    )

    let monteCarloPlayer =
        MonteCarloPlayer(
            playoutsPerMove:
                playoutsPerMove
        )

    var mctsGenerator =
        SplitMix64(seed: 42)

    var monteCarloGenerator =
        SplitMix64(seed: 44)

    var mctsWins = 0
    var monteCarloWins = 0
    var draws = 0

    var mctsWinsAsBlack = 0
    var mctsWinsAsWhite = 0

    let clock = ContinuousClock()
    let start = clock.now

    for gameIndex in 0..<gameCount {
        let mctsColor: Player =
            gameIndex.isMultiple(of: 2)
            ? .black
            : .white

        let outcome =
            try playMCTSAgainstMonteCarlo(
                mctsColor: mctsColor,
                mctsPlayer: mctsPlayer,
                monteCarloPlayer:
                    monteCarloPlayer,
                using: &mctsGenerator,
                monteCarloGenerator:
                    &monteCarloGenerator
            )

        switch outcome {
        case .draw:
            draws += 1

        case .blackWin:
            if mctsColor == .black {
                mctsWins += 1
                mctsWinsAsBlack += 1
            } else {
                monteCarloWins += 1
            }

        case .whiteWin:
            if mctsColor == .white {
                mctsWins += 1
                mctsWinsAsWhite += 1
            } else {
                monteCarloWins += 1
            }
        }
    }

    let elapsed =
        start.duration(to: clock.now)

    let mctsScore =
        (Double(mctsWins)
            + Double(draws) * 0.5)
        / Double(gameCount)

    print(
        "\(gameCount) MCTS versus Monte Carlo games"
    )
    print(
        "MCTS iterations per move:",
        mctsIterationCount
    )
    print(
        "Monte Carlo playouts per legal move:",
        playoutsPerMove
    )
    print("MCTS wins:", mctsWins)
    print(
        "Monte Carlo wins:",
        monteCarloWins
    )
    print("Draws:", draws)
    print(
        "MCTS wins as Black:",
        mctsWinsAsBlack
    )
    print(
        "MCTS wins as White:",
        mctsWinsAsWhite
    )
    print("MCTS score rate:", mctsScore)
    print("Elapsed:", elapsed)
    print(
        "Average:",
        elapsed / gameCount
    )
}

private struct ExactBenchmarkPosition {
    let emptySquareCount: Int
    let record: String
    let expectedMove: String
    let expectedScore: Int
}

private let exactBenchmarkPositions = [
    ExactBenchmarkPosition(
        emptySquareCount: 8,
        record:
            """
            e6f6d3c5b6b5g6c3c6g7b4d2
            c2c1d1f4f3h6e3e7f7e8b3c4
            f5e1b2c7d8e2d6a2d7c8f8a3
            a1g5f2g3h5h7g8a4g2h2h8g4
            h1b7h3h4
            """,
        expectedMove: "a6",
        expectedScore: 42
    ),
    ExactBenchmarkPosition(
        emptySquareCount: 10,
        record:
            """
            e6f6d3c5b6b5g6c3c6g7b4d2
            c2c1d1f4f3h6e3e7f7e8b3c4
            f5e1b2c7d8e2d6a2d7c8f8a3
            a1g5f2g3h5h7g8a4g2h2h8g4
            h1b7
            """,
        expectedMove: "a6",
        expectedScore: 48
    ),
    ExactBenchmarkPosition(
        emptySquareCount: 12,
        record:
            """
            c4e3f3c3e6e7c2g3d3b2f7g7
            f4f5a2b3d6c6d7e8g5f6h2e2
            f8h6a4a3d8h3h5a1e1g8g4d2
            h4g6b4b5b7d1c5c8h8h7c1b1
            """,
        expectedMove: "g2",
        expectedScore: -24
    ),
    ExactBenchmarkPosition(
        emptySquareCount: 14,
        record:
            """
            d3c5e6f7b5e3g8b6b7e7f5g4
            d7a7h3e8f3b4a5f4b3h4h5g6
            g7c7h7c6c8d8c4c3d2d6a6a2
            b2c2b1a8g3f6f8d1c1a1
            """,
        expectedMove: "e2",
        expectedScore: -34
    ),
    ExactBenchmarkPosition(
        emptySquareCount: 16,
        record:
            """
            d3c5e6f7b5e3g8b6b7e7f5g4
            d7a7h3e8f3b4a5f4b3h4h5g6
            g7c7h7c6c8d8c4c3d2d6a6a2
            b2c2b1a8g3f6f8d1
            """,
        expectedMove: "c1",
        expectedScore: -38
    ),
    ExactBenchmarkPosition(
        emptySquareCount: 18,
        record:
            """
            d3c5e6f7b5e3g8b6b7e7f5g4
            d7a7h3e8f3b4a5f4b3h4h5g6
            g7c7h7c6c8d8c4c3d2d6a6a2
            b2c2b1a8g3f6
            """,
        expectedMove: "f8",
        expectedScore: -42
    ),
    ExactBenchmarkPosition(
        emptySquareCount: 20,
        record:
            """
            d3c5e6f7b5e3g8b6b7e7f5g4
            d7a7h3e8f3b4a5f4b3h4h5g6
            g7c7h7c6c8d8c4c3d2d6a6a2
            b2c2b1a8
            """,
        expectedMove: "f8",
        expectedScore: -48
    ),
]

func profileExactSearches(
    trialCount: Int
) throws {
    precondition(trialCount > 0)

    let player = ExactPlayer()
    let clock = ContinuousClock()

    var checksum: UInt64 = 0

    print("Exact search benchmark")
    print(
        "Trials per position:",
        trialCount
    )

    for position
        in exactBenchmarkPositions
    {
        let game =
            try Game(
                replaying: position.record
            )

        var selectedMove: UInt64 = 0
        var score = 0
        var nodeCount = 0
        var cutoffCount = 0
        var transpositionCount = 0
        var transpositionHitCount = 0

        let start = clock.now

        for _ in 0..<trialCount {
            let analysis =
                try player.analyze(
                    in: game
                )

            transpositionCount =
                analysis.transpositionCount

            transpositionHitCount =
                analysis.transpositionHitCount

            selectedMove =
                analysis.move

            score =
                analysis.score

            nodeCount =
                analysis.nodeCount

            cutoffCount =
                analysis.cutoffCount

            checksum &+=
                analysis.move

            checksum &+=
                UInt64(
                    analysis.score + 64
                )

            checksum &+=
                UInt64(
                    analysis.nodeCount
                )

            checksum &+=
                UInt64(
                    analysis.cutoffCount
                )

            checksum &+=
                UInt64(
                    analysis.transpositionCount
                )

            checksum &+=
                UInt64(
                    analysis.transpositionHitCount
                )
        }

        let elapsed =
            start.duration(to: clock.now)

        let selectedSquare =
            try Board.square(
                selectedMove
            )

        precondition(
            selectedSquare
                == position.expectedMove,
            """
            Exact search selected \
            \(selectedSquare), expected \
            \(position.expectedMove)
            """
        )

        precondition(
            score
                == position.expectedScore,
            """
            Exact search produced score \
            \(score), expected \
            \(position.expectedScore)
            """
        )

        print()
        print(
            "Empty squares:",
            position.emptySquareCount
        )
        print(
            "Best move:",
            selectedSquare
        )
        print("Score:", score)
        print(
            "Nodes per search:",
            nodeCount
        )
        print(
            "Cutoffs per search:",
            cutoffCount
        )
        print(
            "Transposition entries per search:",
            transpositionCount
        )
        print(
            "Transposition hits per search:",
            transpositionHitCount
        )
        print("Elapsed:", elapsed)
        print(
            "Average:",
            elapsed / trialCount
        )
    }

    print()
    print(
        "Checksum:",
        String(checksum, radix: 16)
    )
}

let arguments =
    CommandLine.arguments.dropFirst()

let mode =
    arguments.first ?? "games"

switch mode {
case "games":
    let trialCount =
        arguments.dropFirst().first
        .flatMap(Int.init)
        ?? 1_000_000

    try profileGames(
        trialCount: trialCount
    )

case "symmetry":
    let iterations =
        arguments.dropFirst().first
        .flatMap(Int.init)
        ?? 1_000_000

    profileSymmetries(
        iterations: iterations
    )

case "monte-carlo":
    let gameCount =
        arguments.dropFirst().first
        .flatMap(Int.init)
        ?? 100_000

    try profileMonteCarloPlayouts(
        gameCount: gameCount
    )

case "monte-carlo-move":
    let trialCount =
        arguments.dropFirst().first
        .flatMap(Int.init)
        ?? 10_000

    let playoutsPerMove =
        arguments.dropFirst(2).first
        .flatMap(Int.init)
        ?? 8

    try profileMonteCarloSelections(
        trialCount: trialCount,
        playoutsPerMove: playoutsPerMove
    )

case "mcts":
    let gameCount =
        arguments.dropFirst().first
        .flatMap(Int.init)
        ?? 100

    let iterationCount =
        arguments.dropFirst(2).first
        .flatMap(Int.init)
        ?? 4

    try profileMCTSGames(
        gameCount: gameCount,
        iterationCount: iterationCount
    )

case "match":
    let gameCount =
        arguments.dropFirst().first
        .flatMap(Int.init)
        ?? 1_000

    let iterationCount =
        arguments.dropFirst(2).first
        .flatMap(Int.init)
        ?? 64

    try profileMCTSAgainstRandom(
        gameCount: gameCount,
        iterationCount: iterationCount
    )

case "mcts-mc":
    let gameCount =
        arguments.dropFirst().first
        .flatMap(Int.init)
        ?? 100

    let mctsIterationCount =
        arguments.dropFirst(2).first
        .flatMap(Int.init)
        ?? 64

    let playoutsPerMove =
        arguments.dropFirst(3).first
        .flatMap(Int.init)
        ?? 8

    try profileMCTSAgainstMonteCarlo(
        gameCount: gameCount,
        mctsIterationCount:
            mctsIterationCount,
        playoutsPerMove:
            playoutsPerMove
    )

case "exact":
    let trialCount =
        arguments.dropFirst().first
        .flatMap(Int.init)
        ?? 10

    try profileExactSearches(
        trialCount: trialCount
    )

default:
    fatalError(
        """
        Usage:
          bitellova-profile games [count]
          bitellova-profile monte-carlo [games]
          bitellova-profile monte-carlo-move [trials] [playouts-per-move]
          bitellova-profile symmetry [count]
          bitellova-profile mcts [games] [iterations]
          bitellova-profile match [games] [iterations]
          bitellova-profile mcts-mc [games] [mcts-iterations] [mc-playouts-per-move]
          bitellova-profile exact [trials-per-position]
        """
    )
}
