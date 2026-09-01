//
//  MonteCarloPlayerTests.swift
//
//
//  Created by ideguti masaya on 2026/09/01.
//

import Testing

@testable import Bitellova
@testable import BitellovaAI

@Test
func monteCarloPlayerSelectsLegalMove() throws {
    var game = Game()
    let legalMoves = game.legalMoves

    let player = MonteCarloPlayer(
        playoutsPerMove: 32
    )

    var generator = SplitMix64(seed: 42)

    let move = try player.selectMove(
        in: game,
        using: &generator
    )

    #expect(move.nonzeroBitCount == 1)
    #expect(move & legalMoves != 0)
}
