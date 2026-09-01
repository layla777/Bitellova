//
//  MCTSTests.swift
//
//
//  Created by ideguti masaya on 2026/09/02.
//

import Testing

@testable import Bitellova
@testable import BitellovaAI

@Test
func symmetricBoardsShareOneMCTSNode() throws {
    var game = Game()

    try game.play("d3")
    try game.play("c3")

    let board = game.board
    let rotatedBoard = board.transformed(
        by: .rotate90Clockwise
    )

    var mcts = MCTS()

    mcts.ensureNode(for: board)
    mcts.ensureNode(for: rotatedBoard)

    #expect(mcts.nodeCount == 1)
}
