//
//  main.swift
//
//
//  Created by ideguti masaya on 2026/09/04.
//

import Bitellova
import BitellovaAI

private struct MatchResult {
    let outcome: Game.Outcome
    let firstExactScore: Int?
    let exactSearchCount: Int
    let exactNodeCount: Int
    let moves: [UInt64]
}

private func playMCTSAgainstMCTSExact<
    MCTSGenerator: RandomNumberGenerator,
    MCTSExactGenerator: RandomNumberGenerator
>(
    exactColor: Player,
    mctsPlayer: MCTSPlayer,
    exactPlayer: ExactPlayer,
    exactEmptySquareThreshold: Int,
    using mctsGenerator: inout MCTSGenerator,
    mctsExactGenerator: inout MCTSExactGenerator
) throws -> MatchResult {
    var game = Game()

    var firstExactScore: Int?
    var exactSearchCount = 0
    var exactNodeCount = 0

    var moves: [UInt64] = []
    moves.reserveCapacity(60)

    while !game.isGameOver {
        if game.isPass {
            try game.pass()
            continue
        }

        let move: UInt64

        if game.currentPlayer == exactColor {
            if game.board.emptySquareCount
                <= exactEmptySquareThreshold
            {
                let analysis =
                    try exactPlayer.analyze(
                        in: game
                    )

                if firstExactScore == nil {
                    firstExactScore =
                        analysis.score
                }

                exactSearchCount += 1
                exactNodeCount +=
                    analysis.nodeCount
                move = analysis.move
            } else {
                move =
                    try mctsPlayer.selectMove(
                        in: game,
                        using:
                            &mctsExactGenerator
                    )
            }
        } else {
            move =
                try mctsPlayer.selectMove(
                    in: game,
                    using: &mctsGenerator
                )
        }

        try game.play(move)
        moves.append(move)
    }

    guard let outcome = game.outcome else {
        preconditionFailure(
            "MCTS versus MCTS-Exact game produced no outcome"
        )
    }

    return MatchResult(
        outcome: outcome,
        firstExactScore: firstExactScore,
        exactSearchCount: exactSearchCount,
        exactNodeCount: exactNodeCount,
        moves: moves
    )
}

private func runMCTSAgainstMCTSExactMatches(
    gameCount: Int,
    iterationCount: Int,
    exactEmptySquareThreshold: Int
) throws {
    precondition(gameCount > 0)
    precondition(iterationCount > 0)
    precondition(
        (1...60).contains(
            exactEmptySquareThreshold
        )
    )

    let mctsPlayer = MCTSPlayer(
        iterationCount: iterationCount
    )

    let exactPlayer = ExactPlayer()

    var mctsGenerator =
        SplitMix64(seed: 42)

    var mctsExactGenerator =
        SplitMix64(seed: 43)

    var exactWins = 0
    var mctsWins = 0
    var draws = 0

    var exactWinsAsBlack = 0
    var exactWinsAsWhite = 0

    var winningAtTakeover = 0
    var winningConverted = 0

    var drawingAtTakeover = 0
    var drawingWon = 0
    var drawingDrawn = 0

    var losingAtTakeover = 0
    var losingEscaped = 0

    var noTakeover = 0
    var totalExactSearchCount = 0
    var totalExactNodeCount = 0

    let clock = ContinuousClock()
    let start = clock.now

    for gameIndex in 0..<gameCount {
        let exactColor: Player =
            gameIndex.isMultiple(of: 2)
            ? .black
            : .white

        let result =
            try playMCTSAgainstMCTSExact(
                exactColor: exactColor,
                mctsPlayer: mctsPlayer,
                exactPlayer: exactPlayer,
                exactEmptySquareThreshold:
                    exactEmptySquareThreshold,
                using: &mctsGenerator,
                mctsExactGenerator:
                    &mctsExactGenerator
            )

        let exactWon: Bool
        let exactLost: Bool

        switch result.outcome {
        case .draw:
            draws += 1
            exactWon = false
            exactLost = false

        case .blackWin:
            if exactColor == .black {
                exactWins += 1
                exactWinsAsBlack += 1
                exactWon = true
                exactLost = false
            } else {
                mctsWins += 1
                exactWon = false
                exactLost = true
            }

        case .whiteWin:
            if exactColor == .white {
                exactWins += 1
                exactWinsAsWhite += 1
                exactWon = true
                exactLost = false
            } else {
                mctsWins += 1
                exactWon = false
                exactLost = true
            }
        }

        if let score = result.firstExactScore {
            if score > 0 {
                winningAtTakeover += 1

                if exactWon {
                    winningConverted += 1
                }
            } else if score == 0 {
                drawingAtTakeover += 1

                if exactWon {
                    drawingWon += 1
                } else if !exactLost {
                    drawingDrawn += 1
                }
            } else {
                losingAtTakeover += 1

                if !exactLost {
                    losingEscaped += 1
                }
            }
        } else {
            noTakeover += 1
        }

        totalExactSearchCount +=
            result.exactSearchCount
        totalExactNodeCount +=
            result.exactNodeCount

        let exactColorName =
            exactColor == .black
            ? "Black"
            : "White"

        let scoreDescription =
            result.firstExactScore
            .map { String($0) }
            ?? "none"

        let transcript =
            try result.moves
            .map { try Board.square($0) }
            .joined()

        print(
            "Game \(gameIndex + 1):",
            "Exact \(exactColorName),",
            "takeover \(scoreDescription),",
            result.outcome,
            transcript
        )
    }

    let elapsed =
        start.duration(to: clock.now)

    let exactScore =
        (Double(exactWins)
            + Double(draws) * 0.5)
        / Double(gameCount)

    print()
    print(
        "\(gameCount) MCTS versus MCTS-Exact games"
    )
    print(
        "MCTS iterations per move:",
        iterationCount
    )
    print(
        "Exact threshold:",
        exactEmptySquareThreshold,
        "empty squares"
    )
    print("MCTS-Exact wins:", exactWins)
    print("MCTS wins:", mctsWins)
    print("Draws:", draws)
    print(
        "MCTS-Exact wins as Black:",
        exactWinsAsBlack
    )
    print(
        "MCTS-Exact wins as White:",
        exactWinsAsWhite
    )
    print("MCTS-Exact score rate:", exactScore)
    print(
        "Winning at takeover:",
        winningAtTakeover,
        "converted:",
        winningConverted
    )
    print(
        "Drawing at takeover:",
        drawingAtTakeover,
        "won:",
        drawingWon,
        "drawn:",
        drawingDrawn
    )
    print(
        "Losing at takeover:",
        losingAtTakeover,
        "escaped:",
        losingEscaped
    )
    print("Games without takeover:", noTakeover)
    print(
        "Exact searches:",
        totalExactSearchCount
    )
    print(
        "Exact nodes:",
        totalExactNodeCount
    )
    print("Elapsed:", elapsed)
    print(
        "Average:",
        elapsed / gameCount
    )
}

let arguments =
    CommandLine.arguments.dropFirst()

let mode =
    arguments.first ?? "mcts-exact"

switch mode {
case "mcts-exact":
    let gameCount =
        arguments.dropFirst().first
        .flatMap(Int.init)
        ?? 10

    let iterationCount =
        arguments.dropFirst(2).first
        .flatMap(Int.init)
        ?? 64

    let exactEmptySquareThreshold =
        arguments.dropFirst(3).first
        .flatMap(Int.init)
        ?? 20

    try runMCTSAgainstMCTSExactMatches(
        gameCount: gameCount,
        iterationCount: iterationCount,
        exactEmptySquareThreshold:
            exactEmptySquareThreshold
    )

default:
    fatalError(
        """
        Usage:
          bitellova-arena mcts-exact [games] [mcts-iterations] [exact-empty-square-threshold]
        """
    )
}
