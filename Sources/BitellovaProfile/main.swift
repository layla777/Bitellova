//
//  main.swift
//
//
//  Created by ideguti masaya on 2026/09/01.
//

import Bitellova

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

    for symmetry in BoardSymmetry.allCases {
        checksum &+= symmetry.transform(bits)
    }

    return checksum
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

default:
    fatalError(
        "Usage: bitellova-profile [games|symmetry] [count]"
    )
}
