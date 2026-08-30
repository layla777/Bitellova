//
//  GameTests.swift
//
//
//  Created by ideguti masaya on 2026/08/25.
//

import Testing

@testable import Bitellova

@Test
func newGameStartsFromInitialPosition() {
    var game = Game()
    var initialBoard = Board.initialPosition

    #expect(game.board == initialBoard)

    let gameLegalMoves = game.legalMoves
    let initialLegalMoves = initialBoard.legalMoves

    #expect(gameLegalMoves == initialLegalMoves)
}

@Test
func stringAndBitMovesProduceTheSamePosition() throws {
    var stringGame = Game()
    try stringGame.play("d3")

    var bitGame = Game()

    let d3: UInt64 =
        0b00000000_00000000_00010000_00000000_00000000_00000000_00000000_00000000

    try bitGame.play(d3)

    #expect(stringGame.board == bitGame.board)
    #expect(stringGame.board.turn == .white)
}

@Test
func illegalMoveDoesNotChangeGameState() {
    var game = Game()
    let originalBoard = game.board

    #expect(throws: MoveError.self) {
        try game.play("a1")
    }

    #expect(game.board == originalBoard)
}
