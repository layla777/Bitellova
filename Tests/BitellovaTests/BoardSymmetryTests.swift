//
//  BoardSymmetryTests.swift
//
//
//  Created by ideguti masaya on 2026/09/01.
//

import Testing

@testable import Bitellova

private func referenceTransform(
    _ bits: UInt64,
    by symmetry: BoardSymmetry
) -> UInt64 {
    var transformed: UInt64 = 0

    for rank in 1...8 {
        for file in 1...8 {
            let source = bit(
                file: file,
                rank: rank
            )

            guard bits & source != 0 else {
                continue
            }

            let destination:
                (
                    file: Int,
                    rank: Int
                )

            switch symmetry {
            case .identity:
                destination = (
                    file,
                    rank
                )

            case .rotate90Clockwise:
                destination = (
                    9 - rank,
                    file
                )

            case .rotate180:
                destination = (
                    9 - file,
                    9 - rank
                )

            case .rotate270Clockwise:
                destination = (
                    rank,
                    9 - file
                )

            case .flipLeftRight:
                destination = (
                    9 - file,
                    rank
                )

            case .flipTopBottom:
                destination = (
                    file,
                    9 - rank
                )

            case .reflectMainDiagonal:
                destination = (
                    rank,
                    file
                )

            case .reflectAntiDiagonal:
                destination = (
                    9 - rank,
                    9 - file
                )
            }

            transformed |= bit(
                file: destination.file,
                rank: destination.rank
            )
        }
    }

    return transformed
}

private func bit(file: Int, rank: Int) -> UInt64 {
    precondition((1...8).contains(file))
    precondition((1...8).contains(rank))

    let index = (rank - 1) * 8 + (file - 1)
    return UInt64(1) << (63 - index)
}

@Test
func allSymmetriesMapB3Correctly() {
    let b3 = bit(file: 2, rank: 3)

    #expect(
        BoardSymmetry.identity.transform(b3)
            == bit(file: 2, rank: 3)  // b3
    )

    #expect(
        BoardSymmetry.rotate90Clockwise.transform(b3)
            == bit(file: 6, rank: 2)  // f2
    )

    #expect(
        BoardSymmetry.rotate180.transform(b3)
            == bit(file: 7, rank: 6)  // g6
    )

    #expect(
        BoardSymmetry.rotate270Clockwise.transform(b3)
            == bit(file: 3, rank: 7)  // c7
    )

    #expect(
        BoardSymmetry.flipLeftRight.transform(b3)
            == bit(file: 7, rank: 3)  // g3
    )

    #expect(
        BoardSymmetry.flipTopBottom.transform(b3)
            == bit(file: 2, rank: 6)  // b6
    )

    #expect(
        BoardSymmetry.reflectMainDiagonal.transform(b3)
            == bit(file: 3, rank: 2)  // c2
    )

    #expect(
        BoardSymmetry.reflectAntiDiagonal.transform(b3)
            == bit(file: 6, rank: 7)  // f7
    )
}

@Test
func everySymmetryCanBeReversed() {
    let bits: UInt64 =
        0x8123_4567_89AB_CDEF

    for symmetry in BoardSymmetry.allCases {
        let transformed =
            symmetry.transform(bits)

        let restored =
            symmetry.inverse.transform(transformed)

        #expect(restored == bits)
    }
}

@Test
func transformingBoardTransformsDiscsAndPreservesTurn() {
    let board = Board(
        black:
            bit(file: 1, rank: 1)  // a1
            | bit(file: 2, rank: 3),  // b3

        white:
            bit(file: 5, rank: 7)  // e7
            | bit(file: 8, rank: 8),  // h8

        turn: .white
    )

    let transformed = board.transformed(
        by: .rotate90Clockwise
    )

    let expectedBlack =
        bit(file: 8, rank: 1)  // h1
        | bit(file: 6, rank: 2)  // f2

    let expectedWhite =
        bit(file: 2, rank: 5)  // b5
        | bit(file: 1, rank: 8)  // a8

    #expect(transformed.black == expectedBlack)
    #expect(transformed.white == expectedWhite)
    #expect(transformed.turn == .white)
}

@Test
func symmetricBoardsShareCanonicalRepresentation() {
    let board = Board(
        black:
            bit(file: 1, rank: 1)
            | bit(file: 2, rank: 3)
            | bit(file: 6, rank: 4),

        white:
            bit(file: 5, rank: 2)
            | bit(file: 3, rank: 7)
            | bit(file: 8, rank: 8),

        turn: .white
    )

    let canonical = board.canonicalized()

    #expect(
        board.transformed(by: canonical.symmetry)
            == canonical.board
    )

    for symmetry in BoardSymmetry.allCases {
        let equivalentBoard =
            board.transformed(by: symmetry)

        let equivalentCanonical =
            equivalentBoard.canonicalized()

        #expect(
            equivalentCanonical.board
                == canonical.board
        )
    }
}

@Test
func bitboardTransformMatchesReferenceForEverySquare() {
    for symmetry in BoardSymmetry.allCases {
        for rank in 1...8 {
            for file in 1...8 {
                let source = bit(
                    file: file,
                    rank: rank
                )

                let expected = referenceTransform(
                    source,
                    by: symmetry
                )

                let actual =
                    symmetry.transform(source)

                #expect(actual == expected)
            }
        }
    }
}

@Test
func bitboardTransformMatchesReferenceForPatterns() {
    let patterns: [UInt64] = [
        0,
        UInt64.max,
        0x8123_4567_89AB_CDEF,
        0xAA55_AA55_55AA_55AA,
        0x0102_0408_1020_4080,
    ]

    for symmetry in BoardSymmetry.allCases {
        for pattern in patterns {
            let expected = referenceTransform(
                pattern,
                by: symmetry
            )

            let actual =
                symmetry.transform(pattern)

            #expect(actual == expected)
        }
    }
}
