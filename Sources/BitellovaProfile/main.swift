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
) throws -> Game.Outcome {
    var game = Game()

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
    }

    guard let outcome = game.outcome else {
        preconditionFailure(
            "MCTS self-play did not produce an outcome"
        )
    }

    return outcome
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

    let clock = ContinuousClock()
    let start = clock.now

    for _ in 0..<gameCount {
        let outcome =
            try playOneMCTSGame(
                with: player,
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

default:
    fatalError(
        """
        Usage:
          bitellova-profile games [count]
          bitellova-profile symmetry [count]
          bitellova-profile mcts [games] [iterations]
        """
    )
}
