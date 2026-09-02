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

@Test
func mctsSelfPlayReachesGameOver() throws {
    var game = Game()

    var generator =
        SplitMix64(seed: 42)

    let player = MCTSPlayer(
        iterationCount: 4
    )

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

    #expect(game.outcome != nil)
}

@Test
func terminalNodeHasNoPassEdge() {
    let terminalBoard = Board(
        black: UInt64.max,
        white: 0,
        turn: .black
    )

    let node = Node(
        board: terminalBoard
    )

    #expect(node.edges.isEmpty)
}
