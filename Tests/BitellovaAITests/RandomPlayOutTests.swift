//
//  RandomPlayoutTests.swift
//
//
//  Created by ideguti masaya on 2026/09/02.
//

import Testing

@testable import Bitellova
@testable import BitellovaAI

@Test
func randomPlayoutHandlesForcedPassAndReturnsOutcome() throws {
    let board = Board(
        // Black: b1
        black:
            0b01000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        // White: a1
        white:
            0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        turn: .black
    )

    let game = Game(board: board)

    var generator =
        SplitMix64(seed: 42)

    let outcome =
        try RandomPlayout().outcome(
            from: game,
            using: &generator
        )

    #expect(outcome == .whiteWin)
}
