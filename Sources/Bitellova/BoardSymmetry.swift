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

    package func transform(_ bits: UInt64) -> UInt64 {
        var remaining = bits
        var transformed: UInt64 = 0

        while remaining != 0 {
            let sourceBit =
                remaining
                & ~(remaining &- 1)

            let sourceBitPosition =
                sourceBit.trailingZeroBitCount

            let sourceIndex =
                63 - sourceBitPosition

            let sourceRank = sourceIndex / 8
            let sourceFile = sourceIndex % 8

            let destination:
                (
                    rank: Int,
                    file: Int
                )

            switch self {
            case .identity:
                destination = (
                    sourceRank,
                    sourceFile
                )

            case .rotate90Clockwise:
                destination = (
                    sourceFile,
                    7 - sourceRank
                )

            case .rotate180:
                destination = (
                    7 - sourceRank,
                    7 - sourceFile
                )

            case .rotate270Clockwise:
                destination = (
                    7 - sourceFile,
                    sourceRank
                )

            case .flipLeftRight:
                destination = (
                    sourceRank,
                    7 - sourceFile
                )

            case .flipTopBottom:
                destination = (
                    7 - sourceRank,
                    sourceFile
                )

            case .reflectMainDiagonal:
                destination = (
                    sourceFile,
                    sourceRank
                )

            case .reflectAntiDiagonal:
                destination = (
                    7 - sourceFile,
                    7 - sourceRank
                )
            }

            let destinationIndex =
                destination.rank * 8
                + destination.file

            let destinationBitPosition =
                63 - destinationIndex

            transformed |=
                UInt64(1)
                << destinationBitPosition

            remaining &= remaining &- 1
        }

        return transformed
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
    func canonicalized() -> (
        board: Board,
        symmetry: BoardSymmetry
    ) {
        var bestSymmetry =
            BoardSymmetry.identity

        var bestBoard = transformed(
            by: bestSymmetry
        )

        for symmetry
            in BoardSymmetry.allCases.dropFirst()
        {
            let candidate = transformed(
                by: symmetry
            )

            let comesBeforeBest =
                candidate.black < bestBoard.black
                || (candidate.black == bestBoard.black
                    && candidate.white < bestBoard.white)

            if comesBeforeBest {
                bestBoard = candidate
                bestSymmetry = symmetry
            }
        }

        return (
            board: bestBoard,
            symmetry: bestSymmetry
        )
    }
}
