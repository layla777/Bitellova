//
//  Board.swift
//
//
//  Created by ideguti masaya on 2026/08/25.
//

enum Player: UInt8, Hashable {
    case black
    case white
}

struct Board: Hashable, CustomStringConvertible {
    private(set) var black: UInt64
    private(set) var white: UInt64
    private(set) var turn: Player

    // Legal moves are cached because the same position may be queried repeatedly.
    private var cachedLegalMoves: UInt64?

    private static let columnHeader: String = "  A B C D E F G H\n"

    private static let shiftAndMask: [(Int, UInt64)] = [
        (
            -9,
            0b11111110_11111110_11111110_11111110_11111110_11111110_11111110_11111111
        ),
        (-8, UInt64.max),
        (
            -7,
            0b01111111_01111111_01111111_01111111_01111111_01111111_01111111_01111111
        ),
        (
            -1,
            0b11111110_11111110_11111110_11111110_11111110_11111110_11111110_11111110
        ),
        (
            1,
            0b01111111_01111111_01111111_01111111_01111111_01111111_01111111_01111111
        ),
        (
            7,
            0b11111110_11111110_11111110_11111110_11111110_11111110_11111110_11111110
        ),
        (8, UInt64.max),
        (
            9,
            0b11111111_01111111_01111111_01111111_01111111_01111111_01111111_01111111
        ),
    ]

    // MARK: - Initial position

    static var initialPosition: Board {
        let blackDiscs =
            try! bit("e4") | bit("d5")

        let whiteDiscs =
            try! bit("d4") | bit("e5")

        return Board(
            black: blackDiscs,
            white: whiteDiscs,
            turn: .black
        )
    }

    // MARK: - Position information

    var discCounts: (black: Int, white: Int) {
        (
            black: black.nonzeroBitCount,
            white: white.nonzeroBitCount
        )
    }

    var emptySquares: UInt64 {
        ~(black | white)
    }

    var legalMoves: UInt64 {
        mutating get {
            if let cachedLegalMoves {
                return cachedLegalMoves
            }

            let moves = calculateLegalMoves()
            cachedLegalMoves = moves

            return moves
        }
    }

    var legalMoveCount: Int {
        mutating get {
            legalMoves.nonzeroBitCount
        }
    }

    // MARK: - Game operations

    /// Returns the position after playing the specified square.
    ///
    /// The current board is not modified. A new board is returned instead.
    func playedBoard(_ position: String) throws -> Board {
        let move = try Board.bit(position)
        let flipped = flips(for: move)

        guard flipped != 0 else {
            throw MoveError.invalidMove
        }

        switch turn {
        case .black:
            return Board(
                black: black | move | flipped,
                white: white & ~flipped,
                turn: .white
            )

        case .white:
            return Board(
                black: black & ~flipped,
                white: white | move | flipped,
                turn: .black
            )
        }
    }

    // MARK: - Display

    var description: String {
        var board = "\n"
        let blackDiscs = black.nonzeroBitCount
        let whiteDiscs = white.nonzeroBitCount
        let discDifferences: Int = blackDiscs - whiteDiscs

        board += String(
            format: "  Black: %2d %+d\n",
            blackDiscs,
            discDifferences
        )
        board += String(
            format: "  White: %2d %+d\n",
            whiteDiscs,
            -discDifferences
        )
        board += "  "

        // This deliberately calculates the moves without updating the cache.
        // String conversion should not change the logical state of the board.
        let legalMoves = calculateLegalMoves()
        let mustPass = legalMoves == 0
        let gameIsOver =
            emptySquares == 0
            || (mustPass && passedBoard().calculateLegalMoves() == 0)
        if gameIsOver {
            board += "Game over"
        } else {
            if turn == .black {
                board += "Black"
            } else {
                board += "White"
            }
            if mustPass {
                board += " passes"
            } else {
                board += "'s turn"
            }
        }
        board += "\n\n"
        board += Board.columnHeader

        for rank in 0..<8 {
            board += "\(rank + 1) "

            for file in 0..<8 {
                let bitPosition = 63 - (rank * 8 + file)
                let mask = UInt64(1) << bitPosition

                if black & mask != 0 {
                    board += "● "
                } else if white & mask != 0 {
                    board += "○ "
                } else if legalMoves & mask != 0 {
                    board += "• "
                } else {
                    board += "- "
                }
            }

            board += "\(rank + 1)\n"
        }

        board += Board.columnHeader
        board += "\n"

        return board
    }

    // MARK: - Move generation

    private func calculateLegalMoves() -> UInt64 {
        let own = turn == .black ? black : white
        let opponent = turn == .black ? white : black
        let empty = emptySquares

        var moves: UInt64 = 0

        for (shift, mask) in Self.shiftAndMask {
            // All adjacent opponent discs in this direction.
            var captured =
                Self.shifted(own, by: shift, mask: mask) & opponent

            // At most six opponent discs can lie between an own disc
            // and a legal move on an 8x8 board.
            for _ in 0..<5 {
                captured |=
                    Self.shifted(captured, by: shift, mask: mask) & opponent
            }

            // Empty squares immediately beyond the captured sequences.
            moves |=
                Self.shifted(captured, by: shift, mask: mask) & empty
        }

        return moves
    }

    func isLegal(_ move: UInt64) -> Bool {
        guard move.nonzeroBitCount == 1,
            (black | white) & move == 0
        else {
            return false
        }

        let own = turn == .black ? black : white
        let opponent = turn == .black ? white : black

        for (shift, mask) in Self.shiftAndMask {
            if flipsInDirection(
                for: move,
                own: own,
                opponent: opponent,
                shift: shift,
                mask: mask
            ) != 0 {
                return true
            }
        }

        return false
    }

    func flips(for move: UInt64) -> UInt64 {
        // A legal move must contain exactly one bit and target an empty square.
        guard move.nonzeroBitCount == 1,
            (black | white) & move == 0
        else {
            return 0
        }

        let own = turn == .black ? black : white
        let opponent = turn == .black ? white : black

        var allFlips: UInt64 = 0

        for (shift, mask) in Self.shiftAndMask {
            allFlips |= flipsInDirection(
                for: move,
                own: own,
                opponent: opponent,
                shift: shift,
                mask: mask
            )
        }

        return allFlips
    }

    private func flipsInDirection(
        for move: UInt64,
        own: UInt64,
        opponent: UInt64,
        shift: Int,
        mask: UInt64
    ) -> UInt64 {
        var ray = move
        var captured: UInt64 = 0

        for _ in 0..<7 {
            ray = Self.shifted(ray, by: shift, mask: mask)

            if ray & opponent != 0 {
                captured |= ray
                continue
            }

            return ray & own != 0 ? captured : 0
        }

        return 0
    }

    var isPass: Bool {
        mutating get {
            legalMoves == 0
        }
    }

    func passedBoard() -> Board {
        let nextTurn: Player = turn == .black ? .white : .black
        return Board(
            black: black,
            white: white,
            turn: nextTurn
        )
    }

    var isGameOver: Bool {
        mutating get {
            if emptySquares == 0 {
                return true
            }

            guard isPass else {
                return false
            }

            var nextBoard: Board = passedBoard()
            return nextBoard.isPass
        }
    }

    // MARK: - Internal utilities

    /// Converts a square such as "f5" into its corresponding bit.
    private static func bit(_ square: String) throws -> UInt64 {
        let bytes = Array(square.lowercased().utf8)

        guard bytes.count == 2 else {
            throw MoveError.invalidMove
        }

        let file = Int(bytes[0]) - 97
        let rank = Int(bytes[1]) - 49

        guard (0..<8).contains(file),
            (0..<8).contains(rank)
        else {
            throw MoveError.invalidMove
        }

        let bitPosition = 63 - (rank * 8 + file)

        return UInt64(1) << bitPosition
    }

    /// Converts a bit into its corresponding square such as "f5"
    static func square(_ bit: UInt64) throws -> String {
        guard bit.nonzeroBitCount == 1 else {
            throw ValueError.invalidValue
        }

        let index = bit.leadingZeroBitCount
        let rank = index / 8
        let file = index % 8

        let fileCharacter = Character(UnicodeScalar(97 + file)!)
        let rankCharacter = Character(UnicodeScalar(49 + rank)!)

        return "\(fileCharacter)\(rankCharacter)"
    }

    private static func shifted(
        _ bits: UInt64,
        by shift: Int,
        mask: UInt64
    ) -> UInt64 {
        (shift > 0 ? bits >> shift : bits << -shift) & mask
    }

    // MARK: - Hashable

    static func == (lhs: Board, rhs: Board) -> Bool {
        lhs.black == rhs.black && lhs.white == rhs.white && lhs.turn == rhs.turn
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(black)
        hasher.combine(white)
        hasher.combine(turn)
    }
}
