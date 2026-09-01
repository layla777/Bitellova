//
//  BoardSymmetry.swift
//
//
//  Created by ideguti masaya on 2026/09/01.
//

package enum BoardSymmetry: CaseIterable, Sendable {
    case identity
    case rotate90Clockwise
    case rotate180
    case rotate270Clockwise
    case flipLeftRight
    case flipTopBottom
    case reflectMainDiagonal
    case reflectAntiDiagonal

    @inline(__always)
    package func transform(_ bits: UInt64) -> UInt64 {
        switch self {
        case .identity:
            return bits

        case .rotate90Clockwise:
            return Self.reverseFiles(
                Self.transposeMainDiagonal(bits)
            )

        case .rotate180:
            return Self.reverseFiles(
                Self.reverseRanks(bits)
            )

        case .rotate270Clockwise:
            return Self.reverseRanks(
                Self.transposeMainDiagonal(bits)
            )

        case .flipLeftRight:
            return Self.reverseFiles(bits)

        case .flipTopBottom:
            return Self.reverseRanks(bits)

        case .reflectMainDiagonal:
            return Self.transposeMainDiagonal(bits)

        case .reflectAntiDiagonal:
            return Self.reverseFiles(
                Self.reverseRanks(
                    Self.transposeMainDiagonal(bits)
                )
            )
        }
    }

    package var inverse: BoardSymmetry {
        switch self {
        case .identity:
            return .identity

        case .rotate90Clockwise:
            return .rotate270Clockwise

        case .rotate180:
            return .rotate180

        case .rotate270Clockwise:
            return .rotate90Clockwise

        case .flipLeftRight:
            return .flipLeftRight

        case .flipTopBottom:
            return .flipTopBottom

        case .reflectMainDiagonal:
            return .reflectMainDiagonal

        case .reflectAntiDiagonal:
            return .reflectAntiDiagonal
        }
    }
}

extension Board {
    @inline(__always)
    func transformed(
        by symmetry: BoardSymmetry
    ) -> Board {
        Board(
            black: symmetry.transform(black),
            white: symmetry.transform(white),
            turn: turn
        )
    }
}

extension Board {
    package func canonicalized() -> (
        board: Board,
        symmetry: BoardSymmetry
    ) {
        var bestBoard = transformed(by: .identity)
        var bestSymmetry = BoardSymmetry.identity

        func consider(_ symmetry: BoardSymmetry) {
            let candidate = transformed(by: symmetry)

            let comesBeforeBest =
                candidate.black < bestBoard.black
                || (candidate.black == bestBoard.black
                    && candidate.white < bestBoard.white)

            if comesBeforeBest {
                bestBoard = candidate
                bestSymmetry = symmetry
            }
        }

        consider(.rotate90Clockwise)
        consider(.rotate180)
        consider(.rotate270Clockwise)
        consider(.flipLeftRight)
        consider(.flipTopBottom)
        consider(.reflectMainDiagonal)
        consider(.reflectAntiDiagonal)

        return (
            board: bestBoard,
            symmetry: bestSymmetry
        )
    }
}

extension BoardSymmetry {
    fileprivate static func reverseFiles(
        _ bits: UInt64
    ) -> UInt64 {
        var value = bits

        value =
            ((value >> 1)
                & 0x5555_5555_5555_5555)
            | ((value
                & 0x5555_5555_5555_5555)
                << 1)

        value =
            ((value >> 2)
                & 0x3333_3333_3333_3333)
            | ((value
                & 0x3333_3333_3333_3333)
                << 2)

        value =
            ((value >> 4)
                & 0x0F0F_0F0F_0F0F_0F0F)
            | ((value
                & 0x0F0F_0F0F_0F0F_0F0F)
                << 4)

        return value
    }

    fileprivate static func reverseRanks(
        _ bits: UInt64
    ) -> UInt64 {
        bits.byteSwapped
    }

    fileprivate static func transposeMainDiagonal(
        _ bits: UInt64
    ) -> UInt64 {
        var value = bits

        var swap =
            (value ^ (value >> 7))
            & 0x00AA_00AA_00AA_00AA

        value ^=
            swap ^ (swap << 7)

        swap =
            (value ^ (value >> 14))
            & 0x0000_CCCC_0000_CCCC

        value ^=
            swap ^ (swap << 14)

        swap =
            (value ^ (value >> 28))
            & 0x0000_0000_F0F0_F0F0

        value ^=
            swap ^ (swap << 28)

        return value
    }
}
