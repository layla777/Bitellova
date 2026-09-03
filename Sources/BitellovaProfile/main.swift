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

default:
    fatalError(
        """
        Usage:
          bitellova-profile games [count]
          bitellova-profile symmetry [count]
          bitellova-profile mcts [games] [iterations]
          bitellova-profile match [games] [iterations]
          bitellova-profile mcts-mc [games] [mcts-iterations] [mc-playouts-per-move]
        """
    )
}
