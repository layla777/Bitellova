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

    private static let leftShiftPairs = (
        (
            shifts: SIMD2<UInt64>(9, 8),
            masks: SIMD2<UInt64>(
                shiftAndMask[0].1,
                shiftAndMask[1].1
            )
        ),
        (
            shifts: SIMD2<UInt64>(7, 1),
            masks: SIMD2<UInt64>(
                shiftAndMask[2].1,
                shiftAndMask[3].1
            )
        )
    )

    private static let rightShiftPairs = (
        (
            shifts: SIMD2<UInt64>(1, 7),
            masks: SIMD2<UInt64>(
                shiftAndMask[4].1,
                shiftAndMask[5].1
            )
        ),
        (
            shifts: SIMD2<UInt64>(8, 9),
            masks: SIMD2<UInt64>(
                shiftAndMask[6].1,
                shiftAndMask[7].1
            )
        )
    )

    private static let blackInitialPositions: UInt64 =
        0b00000000_00000000_00000000_00001000_00010000_00000000_00000000_00000000
    private static let whiteInitialPositions: UInt64 =
        0b00000000_00000000_00000000_00010000_00001000_00000000_00000000_00000000

    // MARK: - Initial position

    static let initialPosition = Board(
        black: blackInitialPositions,
        white: whiteInitialPositions,
        turn: .black
    )

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
    func playedBoard(_ move: UInt64) throws -> Board {
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

    func playedBoard(_ position: String) throws -> Board {
        try playedBoard(Board.bit(position))
    }

    // MARK: - Display

    var description: String {
        var board = "\n"

        // This deliberately calculates the moves without updating the cache.
        // String conversion should not change the logical state of the board.
        let legalMoves = calculateLegalMoves()
        let mustPass = legalMoves == 0
        let score = calculateFinalScore(legalMoves: legalMoves)
        let gameIsOver = score != nil
        let counts = score ?? discCounts

        let blackDiscs = counts.black
        let whiteDiscs = counts.white
        let discDifferences = blackDiscs - whiteDiscs

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

    private func calculateLegalMovesReference() -> UInt64 {
        let own = turn == .black ? black : white
        let opponent = turn == .black ? white : black
        let empty = emptySquares

        var moves: UInt64 = 0

        for (shift, mask) in Self.shiftAndMask {
            var captured =
                Self.shifted(own, by: shift, mask: mask) & opponent

            for _ in 0..<5 {
                captured |=
                    Self.shifted(captured, by: shift, mask: mask) & opponent
            }

            moves |=
                Self.shifted(captured, by: shift, mask: mask) & empty
        }

        return moves
    }

    private func calculateLegalMoves() -> UInt64 {
        let own = SIMD2<UInt64>(
            repeating: turn == .black ? black : white
        )
        let opponent = SIMD2<UInt64>(
            repeating: turn == .black ? white : black
        )
        let empty = SIMD2<UInt64>(repeating: emptySquares)

        var moves = SIMD2<UInt64>.zero

        moves |= Self.legalMovesShiftedLeft(
            own: own,
            opponent: opponent,
            empty: empty,
            shifts: Self.leftShiftPairs.0.shifts,
            masks: Self.leftShiftPairs.0.masks
        )

        moves |= Self.legalMovesShiftedLeft(
            own: own,
            opponent: opponent,
            empty: empty,
            shifts: Self.leftShiftPairs.1.shifts,
            masks: Self.leftShiftPairs.1.masks
        )

        moves |= Self.legalMovesShiftedRight(
            own: own,
            opponent: opponent,
            empty: empty,
            shifts: Self.rightShiftPairs.0.shifts,
            masks: Self.rightShiftPairs.0.masks
        )

        moves |= Self.legalMovesShiftedRight(
            own: own,
            opponent: opponent,
            empty: empty,
            shifts: Self.rightShiftPairs.1.shifts,
            masks: Self.rightShiftPairs.1.masks
        )

        let result = moves[0] | moves[1]
        return result
    }

    private static func legalMovesShiftedLeft(
        own: SIMD2<UInt64>,
        opponent: SIMD2<UInt64>,
        empty: SIMD2<UInt64>,
        shifts: SIMD2<UInt64>,
        masks: SIMD2<UInt64>
    ) -> SIMD2<UInt64> {
        var captured =
            ((own &<< shifts) & masks) & opponent

        for _ in 0..<5 {
            captured |=
                ((captured &<< shifts) & masks) & opponent
        }

        return ((captured &<< shifts) & masks) & empty
    }

    private static func legalMovesShiftedRight(
        own: SIMD2<UInt64>,
        opponent: SIMD2<UInt64>,
        empty: SIMD2<UInt64>,
        shifts: SIMD2<UInt64>,
        masks: SIMD2<UInt64>
    ) -> SIMD2<UInt64> {
        var captured =
            ((own &>> shifts) & masks) & opponent

        for _ in 0..<5 {
            captured |=
                ((captured &>> shifts) & masks) & opponent
        }

        return ((captured &>> shifts) & masks) & empty
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

    private func calculateGameIsOver(
        legalMoves: UInt64
    ) -> Bool {
        emptySquares == 0
            || (legalMoves == 0
                && passedBoard().calculateLegalMoves() == 0)
    }

    var isGameOver: Bool {
        mutating get {
            if emptySquares == 0 {
                return true
            }

            return calculateGameIsOver(legalMoves: legalMoves)
        }
    }

    private func calculateFinalScore(
        legalMoves: UInt64
    ) -> (black: Int, white: Int)? {
        guard calculateGameIsOver(legalMoves: legalMoves) else {
            return nil
        }

        let blackDiscs = black.nonzeroBitCount
        let whiteDiscs = white.nonzeroBitCount
        let emptyDiscs = 64 - blackDiscs - whiteDiscs

        if blackDiscs > whiteDiscs {
            return (blackDiscs + emptyDiscs, whiteDiscs)
        }

        if whiteDiscs > blackDiscs {
            return (blackDiscs, whiteDiscs + emptyDiscs)
        }

        return (32, 32)
    }

    var finalScore: (black: Int, white: Int)? {
        calculateFinalScore(legalMoves: calculateLegalMoves())
    }

    // MARK: - Internal utilities

    private static let squareNames: [String] = (0..<64).map { index in
        let file = Character(UnicodeScalar(97 + index % 8)!)
        let rank = Character(UnicodeScalar(49 + index / 8)!)
        return "\(file)\(rank)"
    }

    private static let bitsBySquare: [String: UInt64] = {
        var result: [String: UInt64] = [:]
        result.reserveCapacity(128)

        for (index, square) in squareNames.enumerated() {
            let bit = UInt64(1) << (63 - index)
            result[square] = bit
            result[square.uppercased()] = bit
        }

        return result
    }()

    /// Converts a square such as "f5" into its corresponding bit.
    private static func bit(_ square: String) throws -> UInt64 {
        guard let bit = bitsBySquare[square] else {
            throw MoveError.invalidMove
        }

        return bit
    }

    /// Converts a bit into its corresponding square such as "f5"
    static func square(_ bit: UInt64) throws -> String {
        guard bit.nonzeroBitCount == 1 else {
            throw ValueError.invalidValue
        }

        return squareNames[bit.leadingZeroBitCount]
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
