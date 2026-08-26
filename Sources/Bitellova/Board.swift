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
    
    // MARK: - Initial position
    
    static var initialPosition: Board {
        let blackDiscs =
            try! bit("e4") |
            bit("d5")
        
        let whiteDiscs =
            try! bit("d4") |
            bit("e5")
        
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
        
        board += String(format: "  Black: %2d %+d\n", blackDiscs, discDifferences)
        board += String(format: "  White: %2d %+d\n", whiteDiscs, -discDifferences)
        board += "  "
        if turn == .black {
            board += "Black"
        } else {
            board += "White"
        }
        board += "'s turn\n\n"
        board += Board.columnHeader
        
        // This deliberately calculates the moves without updating the cache.
        // String conversion should not change the logical state of the board.
        let legalMoves = calculateLegalMoves()
        
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
        var currentBit: UInt64 = 1 << 63
        var legalMoves: UInt64 = 0
        
        while currentBit != 0 {
            let occupied = (black | white) & currentBit != 0
            
            if !occupied && isLegal(currentBit) {
                legalMoves |= currentBit
            }
            
            currentBit >>= 1
        }
        
        return legalMoves
    }
    
    func isLegal(_ move: UInt64) -> Bool {
        flips(for: move) != 0
    }
    
    func flips(for move: UInt64) -> UInt64 {
        // A legal move must contain exactly one bit and target an empty square.
        guard move.nonzeroBitCount == 1,
              (black | white) & move == 0
        else {
            return 0
        }
        
        let index = move.leadingZeroBitCount
        let rank = index / 8
        let file = index % 8
        
        let own = turn == .black ? black : white
        let opponent = turn == .black ? white : black
        
        let directions = [
            (-1, -1), (-1, 0), (-1, 1),
            ( 0, -1),          ( 0, 1),
            ( 1, -1), ( 1, 0), ( 1, 1)
        ]
        
        var allFlips: UInt64 = 0
        
        for (rankDelta, fileDelta) in directions {
            var nextRank = rank + rankDelta
            var nextFile = file + fileDelta
            var candidates: UInt64 = 0
            
            while (0..<8).contains(nextRank),
                  (0..<8).contains(nextFile) {
                
                let nextIndex = nextRank * 8 + nextFile
                let nextBit = UInt64(1) << (63 - nextIndex)
                
                if opponent & nextBit != 0 {
                    candidates |= nextBit
                } else if own & nextBit != 0 {
                    allFlips |= candidates
                    break
                } else {
                    break
                }
                
                nextRank += rankDelta
                nextFile += fileDelta
            }
        }
        
        return allFlips
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
    
    /// converts a bit into its corresspoindig square such as "f5"
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
    
    // MARK: - Hashable
    
    static func == (lhs: Board, rhs: Board) -> Bool {
        lhs.black == rhs.black &&
        lhs.white == rhs.white &&
        lhs.turn == rhs.turn
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(black)
        hasher.combine(white)
        hasher.combine(turn)
    }
}
