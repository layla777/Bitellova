//
//  BoardTests.swift
//
//
//  Created by ideguti masaya on 2026/08/25.
//

import Testing

@testable import Bitellova

@Test
func initialPositionHasFourLegalMoves() {
    var board = Board.initialPosition

    let expectedMoves: UInt64 =
        0b00000000_00000000_00010000_00100000_00000100_00001000_00000000_00000000

    #expect(board.legalMoves == expectedMoves)
    #expect(board.legalMoveCount == 4)
}

@Test
func playingD3ProducesExpectedWhiteMoves() throws {
    let board = Board.initialPosition
    var played = try board.playedBoard("d3")

    // After d3, White can play c3, e3, or c5.
    let expectedMoves: UInt64 =
        0b00000000_00000000_00101000_00000000_00100000_00000000_00000000_00000000

    #expect(played.legalMoves == expectedMoves)
    #expect(played.legalMoveCount == 3)
}

@Test(arguments: ["d3", "c4", "f5", "e6"])
func everyInitialLegalMoveCanBePlayed(_ square: String) throws {
    let board = Board.initialPosition

    _ = try board.playedBoard(square)
}

@Test(arguments: ["a1", "d4", "e4"])
func illegalInitialMoveIsRejected(_ square: String) {
    let board = Board.initialPosition

    #expect(throws: MoveError.self) {
        try board.playedBoard(square)
    }
}

@Test
func playingD3FlipsD4() throws {
    let board = Board.initialPosition
    let played = try board.playedBoard("d3")

    let expectedBlack: UInt64 =
        0b00000000_00000000_00010000_00011000_00010000_00000000_00000000_00000000

    let expectedWhite: UInt64 =
        0b00000000_00000000_00000000_00000000_00001000_00000000_00000000_00000000

    #expect(played.black == expectedBlack)
    #expect(played.white == expectedWhite)
    #expect(played.turn == .white)
}

@Test
func legalMovesCacheDoesNotChangeBoardIdentity() {
    var cachedBoard = Board.initialPosition
    let uncachedBoard = Board.initialPosition

    _ = cachedBoard.legalMoves

    #expect(cachedBoard == uncachedBoard)
    #expect(cachedBoard.hashValue == uncachedBoard.hashValue)
}

@Test
func oneMoveFlipsAllEightDirections() throws {
    let board = Board(
        black:
            0b00000000_01010100_00000000_01000100_00000000_01010100_00000000_00000000,
        white:
            0b00000000_00000000_00111000_00101000_00111000_00000000_00000000_00000000,
        turn: .black
    )

    let d4: UInt64 =
        0b00000000_00000000_00000000_00010000_00000000_00000000_00000000_00000000

    let played = try board.playedBoard(d4)

    let expectedBlack: UInt64 =
        0b00000000_01010100_00111000_01111100_00111000_01010100_00000000_00000000

    #expect(played.black == expectedBlack)
    #expect(played.white == 0)
    #expect(played.turn == .white)
}

@Test
func eliminationProducesSixtyFourToZero() {
    var blackWinner = Board(
        black:
            0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
        white: 0,
        turn: .black
    )

    let blackGameIsOver = blackWinner.isGameOver
    #expect(blackGameIsOver)

    let blackScore = blackWinner.finalScore
    #expect(blackScore?.black == 64)
    #expect(blackScore?.white == 0)

    var whiteWinner = Board(
        black: 0,
        white:
            0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000001,
        turn: .white
    )

    let whiteGameIsOver = whiteWinner.isGameOver
    #expect(whiteGameIsOver)

    let whiteScore = whiteWinner.finalScore
    #expect(whiteScore?.black == 0)
    #expect(whiteScore?.white == 64)
}

@Test
func terminalWinnerReceivesAllEmptySquares() {
    var board = Board(
        black:
            0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000001,
        white:
            0b00000000_00000000_00000000_00010000_00000000_00000000_00000000_00000000,
        turn: .black
    )

    let gameIsOver = board.isGameOver
    #expect(gameIsOver)

    let score = board.finalScore
    #expect(score?.black == 63)
    #expect(score?.white == 1)
}

@Test
func terminalTieProducesThirtyTwoEach() {
    var board = Board(
        black:
            0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
        white:
            0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000001,
        turn: .black
    )

    let gameIsOver = board.isGameOver
    #expect(gameIsOver)

    let score = board.finalScore
    #expect(score?.black == 32)
    #expect(score?.white == 32)
}

@Test
func passChangesTurnWhenOpponentHasALegalMove() {
    var board = Board(
        // Black: b1
        black:
            0b01000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        // White: a1
        white:
            0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        turn: .black
    )

    let mustPass = board.isPass
    let gameIsOver = board.isGameOver

    #expect(mustPass)
    #expect(gameIsOver == false)

    var passed = board.passedBoard()

    // c1
    let c1: UInt64 =
        0b00100000_00000000_00000000_00000000_00000000_00000000_00000000_00000000

    let passedLegalMoves = passed.legalMoves

    #expect(passed.turn == .white)
    #expect(passed.black == board.black)
    #expect(passed.white == board.white)
    #expect(passedLegalMoves == c1)
}

@Test
func SIMDFlipsMatchReferenceForReachablePositions() throws {
    for gameNumber in 0..<64 {
        var board = Board.initialPosition
        var ply = 0

        while !board.isGameOver {
            if board.isPass {
                board = board.passedBoard()
                continue
            }

            let legalMoves = board.legalMoves
            var remainingMoves = legalMoves

            while remainingMoves != 0 {
                let move =
                    remainingMoves
                    & ~(remainingMoves &- 1)

                remainingMoves &=
                    remainingMoves &- 1

                #expect(
                    board.flipsUsingSIMD(
                        for: move
                    )
                        == board.flips(
                            for: move
                        )
                )
            }

            let selectedIndex =
                (gameNumber + ply * 7)
                % legalMoves.nonzeroBitCount

            let selectedMove =
                setBit(
                    in: legalMoves,
                    at: selectedIndex
                )

            board =
                try board.playedBoard(
                    selectedMove
                )

            ply += 1
        }
    }
}

private func setBit(
    in bits: UInt64,
    at index: Int
) -> UInt64 {
    precondition(
        0..<bits.nonzeroBitCount
            ~= index
    )

    var remainingBits = bits

    for _ in 0..<index {
        remainingBits &=
            remainingBits &- 1
    }

    return remainingBits
        & ~(remainingBits &- 1)
}
