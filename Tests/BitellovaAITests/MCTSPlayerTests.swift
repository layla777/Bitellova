//
//  MCTSPlayerTests.swift
//
//
//  Created by ideguti masaya on 2026/09/02.
//

import Testing

@testable import Bitellova
@testable import BitellovaAI

@Test
func mctsPlayerSelectsLegalMove() throws {
    let game = Game()

    var gameForMoves = game
    let legalMoves =
        gameForMoves.legalMoves

    var generator =
        SplitMix64(seed: 42)

    let player = MCTSPlayer(
        iterationCount: 64
    )

    let move =
        try player.selectMove(
            in: game,
            using: &generator
        )

    #expect(move.nonzeroBitCount == 1)
    #expect(legalMoves & move != 0)
}
