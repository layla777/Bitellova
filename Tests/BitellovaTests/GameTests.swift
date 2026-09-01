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

@Test
func gameCanStartFromSpecifiedBoard() throws {
    let initialBoard = Board.initialPosition
    let specifiedBoard = try initialBoard.playedBoard("d3")

    let game = Game(board: specifiedBoard)

    #expect(game.board == specifiedBoard)
    #expect(game.board.turn == .white)
}

@Test
func replayingRecordProducesExpectedBoard() throws {
    var manualGame = Game()
    try manualGame.play("f5")
    try manualGame.play("f6")

    let replayedGame = try Game(replaying: "f5f6")

    #expect(replayedGame.board == manualGame.board)
    #expect(replayedGame.board.turn == .black)
}

@Test
func incompleteMoveRecordIsRejected() {
    #expect(throws: Game.GameError.self) {
        try Game(replaying: "f5f")
    }
}

@Test
func replayCanStartFromSpecifiedBoard() throws {
    let initialBoard = Board.initialPosition
    let specifiedBoard = try initialBoard.playedBoard("d3")

    var manualGame = Game(board: specifiedBoard)
    try manualGame.play("c3")

    let replayedGame = try Game(
        replaying: "c3",
        from: specifiedBoard
    )

    #expect(replayedGame.board == manualGame.board)
    #expect(replayedGame.board.turn == .black)
}

@Test
func replayAutomaticallyPassesWhenRequired() throws {
    let passRequiredBoard = Board(
        // Black: b1
        black:
            0b01000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        // White: a1
        white:
            0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        turn: .black
    )

    var manualGame = Game(board: passRequiredBoard)
    try manualGame.pass()
    try manualGame.play("c1")

    let replayedGame = try Game(
        replaying: "c1",
        from: passRequiredBoard
    )

    #expect(replayedGame.board == manualGame.board)
}

@Test(arguments: [
    "F5F6",
    "f5 f6",
    "f5\nf6",
])

func replayAcceptsFormattedRecords(_ record: String) throws {
    let expectedGame = try Game(replaying: "f5f6")
    let replayedGame = try Game(replaying: record)

    #expect(replayedGame.board == expectedGame.board)
}

// Verified with mEdax: White wins 50–14.
@Test
func replayingCompleteGameProducesKnownFinalPosition() throws {
    let record = """
        d3e3f2c3e6f3g2f5e2d6
        b3f4g4h4c5e1h3h1h5c4
        d2g6g5f6h7g3f7b6b4e7
        b5h6h2g8c7d1d7a4e8h8
        g7a6a3f8b7b8c6a2d8c1
        b2a1c2b1a5a8a7c8g1f1
        """

    var game = try Game(replaying: record)

    let gameIsOver = game.isGameOver
    #expect(gameIsOver)

    let expectedBlack: UInt64 =
        0b00000100_00001011_01000001_00100001_00000001_01010010_10001000_00000000

    let expectedWhite: UInt64 =
        0b11111011_11110100_10111110_11011110_11111110_10101101_01110111_11111111

    #expect(game.board.black == expectedBlack)
    #expect(game.board.white == expectedWhite)
    #expect(game.board.turn == .white)

    let finalBoard = game.board
    let score = finalBoard.finalScore

    #expect(score?.black == 14)
    #expect(score?.white == 50)
}
