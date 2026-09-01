//
//  RandomPlayerTests.swift
//
//
//  Created by ideguti masaya on 2026/09/01.
//

import Testing

@testable import Bitellova
@testable import BitellovaAI

@Test
func randomPlayerAlwaysSelectsOneLegalMove() {
    var generator = SplitMix64(seed: 42)
    let player = RandomPlayer()

    let legalMoves: UInt64 =
        0b00000000_00000000_00010000_00100000_00000100_00001000_00000000_00000000

    for _ in 0..<100 {
        let move = player.selectMove(
            from: legalMoves,
            using: &generator
        )

        #expect(move.nonzeroBitCount == 1)
        #expect(move & legalMoves != 0)
    }
}

@Test
func randomSelfPlayReachesGameOver() throws {
    var game = Game()
    var generator = SplitMix64(seed: 42)
    let player = RandomPlayer()

    while !game.isGameOver {
        if game.isPass {
            try game.pass()
            continue
        }

        let legalMoves = game.legalMoves
        let move = player.selectMove(
            from: legalMoves,
            using: &generator
        )

        #expect(move.nonzeroBitCount == 1)
        #expect(move & legalMoves != 0)

        try game.play(move)
    }

    let gameIsOver = game.isGameOver
    #expect(gameIsOver)
}
