//
//  Game.swift
//
//
//  Created by ideguti masaya on 2026/08/25.
//

struct Game {
    enum GameError: Error {
        case passNotAllowed
        case gameAlreadyOver
        case incompleteMoveRecord
    }

    private(set) var board: Board

    init(board: Board = .initialPosition) {
        self.board = board
    }

    init(
        replaying record: String,
        from board: Board = .initialPosition
    ) throws {
        self.init(board: board)

        guard record.count.isMultiple(of: 2) else {
            throw GameError.incompleteMoveRecord
        }

        var start = record.startIndex

        while start < record.endIndex {
            let end = record.index(start, offsetBy: 2)
            let position = String(record[start..<end])

            let gameIsOver = isGameOver

            guard !gameIsOver else {
                throw GameError.gameAlreadyOver
            }

            let mustPass = isPass

            if mustPass {
                try pass()
            }

            try play(position)

            start = end
        }
    }

    mutating func play(_ move: UInt64) throws {
        board = try board.playedBoard(move)
    }

    mutating func play(_ position: String) throws {
        board = try board.playedBoard(position)
    }

    mutating func pass() throws {
        guard !isGameOver else {
            throw GameError.gameAlreadyOver
        }

        guard isPass else {
            throw GameError.passNotAllowed
        }

        board = board.passedBoard()
    }

    var legalMoves: UInt64 {
        mutating get {
            board.legalMoves
        }
    }

    var isPass: Bool {
        mutating get {
            board.isPass
        }
    }

    var isGameOver: Bool {
        mutating get {
            board.isGameOver
        }
    }
}
