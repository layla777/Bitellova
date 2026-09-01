//
//  Game.swift
//
//
//  Created by ideguti masaya on 2026/08/25.
//

package struct Game {
    package enum Outcome: Equatable {
        case blackWin
        case whiteWin
        case draw
    }

    enum GameError: Error {
        case passNotAllowed
        case gameAlreadyOver
        case incompleteMoveRecord
    }

    private(set) var board: Board

    package init() {
        self.init(board: .initialPosition)
    }

    init(board: Board) {
        self.board = board
    }

    init(
        replaying record: String,
        from board: Board = .initialPosition
    ) throws {
        self.init(board: board)

        let normalizedRecord = String(
            record.filter { !$0.isWhitespace }
        )

        guard normalizedRecord.count.isMultiple(of: 2) else {
            throw GameError.incompleteMoveRecord
        }

        var start = normalizedRecord.startIndex

        while start < normalizedRecord.endIndex {
            let end = normalizedRecord.index(
                start,
                offsetBy: 2
            )

            let position = String(
                normalizedRecord[start..<end]
            )

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

    package mutating func play(_ move: UInt64) throws {
        board = try board.playedBoard(move)
    }

    package mutating func play(_ position: String) throws {
        board = try board.playedBoard(position)
    }

    package mutating func pass() throws {
        guard !isGameOver else {
            throw GameError.gameAlreadyOver
        }

        guard isPass else {
            throw GameError.passNotAllowed
        }

        board = board.passedBoard()
    }

    package var legalMoves: UInt64 {
        mutating get {
            board.legalMoves
        }
    }

    package var isPass: Bool {
        mutating get {
            board.isPass
        }
    }

    package var isGameOver: Bool {
        mutating get {
            board.isGameOver
        }
    }

    package var outcome: Outcome? {
        mutating get {
            guard let score = board.finalScore else {
                return nil
            }

            if score.black > score.white {
                return .blackWin
            }

            if score.white > score.black {
                return .whiteWin
            }

            return .draw
        }
    }
}
