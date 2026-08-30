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
    }

    private(set) var board: Board

    init() {
        board = .initialPosition
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
