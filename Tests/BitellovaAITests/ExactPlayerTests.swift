//
//  ExactPlayerTests.swift
//
//
//  Created by ideguti masaya on 2026/09/04.
//

import Testing

@testable import Bitellova
@testable import BitellovaAI

private func selectedSquare(
    replaying record: String
) throws -> String {
    let game =
        try Game(replaying: record)

    let move =
        try ExactPlayer()
        .selectMove(in: game)

    return try Board.square(move)
}

@Test
func exactPlayerSelectsBestFinalScore() throws {
    let game = try Game(
        replaying:
            """
            f5f4d3f6g5d6g7c4d7c2e3h8
            c3d2b4f3f2h6g4d8c7h4e6e7
            f8c5e1b8f7b2c8e2a8g6d1a3
            b3b1h7g8a2e8b5a4c6b6b7a7
            a5a1g2g3c1
            """
    )

    let player = ExactPlayer()
    let move =
        try player.selectMove(in: game)

    // White's exact scores:
    // a6: +28, f1: -2, g1: -6,
    // h1: -6, h2: -8
    #expect(
        try Board.square(move) == "a6"
    )
}

@Test
func exactPlayerHandlesPassDuringSearch() throws {
    let game = try Game(
        replaying:
            """
            f5f6c4g5h5h4g7c5e6e7h3d7
            c6d3d8b5d6f7e3e8f8h8b7f4
            c7d2c3b2g8c8a5a4b3a8b6a2
            b8b4b1a1f2a7d1g1c2a3g3h6
            g4g6e2g2a6e1c1h2
            """
    )

    let player = ExactPlayer()
    let move =
        try player.selectMove(in: game)

    // Black's exact scores:
    // f1: +8, f3: +16, h7: +12
    // White must pass after f3.
    #expect(
        try Board.square(move) == "f3"
    )
}

@Test
func exactPlayerSelectsOnlyLegalMove() throws {
    let square =
        try selectedSquare(
            replaying:
                """
                d3c5c6c7f5e3e2g5g6f4d6g7
                b7e7g4a7c8d2e6f2c3b8a6f6
                e8d8h6a8f3b2f7h4b6b4h8d7
                b3b5f1g1b1a3c2a2a1h7h5a5
                g2g3c4e1c1d1f8
                """
        )

    #expect(square == "g8")
}

@Test
func exactPlayerMinimizesLoss() throws {
    let square =
        try selectedSquare(
            replaying:
                """
                c4c3c2e3d3b1e2c6f6c5f3f2
                f5g2g3h4b5b4h3g6h7e6h2h6
                g7f8c7g4b2h8a4a1g5d6h5g1
                f7b8h1b6b3d2a6d7c1e7d1a7
                a2a3d8e1c8
                """
        )

    // White's exact scores:
    // f4: -8, a5: -18,
    // b7: -18, e8: -18
    #expect(square == "f4")
}

@Test
func exactPlayerPrefersDrawToLoss() throws {
    let square =
        try selectedSquare(
            replaying:
                """
                d3e3f3c3c4e2d1c6b7g3f2c5
                e6g1b5f4h3a8g4b6d2h4c2a5
                d6g2f1c7f6b2b8d8a2b4a6d7
                h5a1e8c8a4g5h6f8b3b1f5a7
                c1h2e7h7h1g7
                """
        )

    // Black's exact scores:
    // a3: 0, e1: -6, g6: -22,
    // h8: -22, f7: -28
    #expect(square == "a3")
}

@Test
func exactPlayerSelectsOneOfTiedBestMoves() throws {
    let square =
        try selectedSquare(
            replaying:
                """
                f5d6c3d3c7f3c2b2b3b4a4g5
                c6d2f4d7b5g4d1a5d8c5a1b7
                g3e3a3e8e7f7f2g2f8a2c8f1
                b6e6f6g7g1h1h5e1h3g6h6b1
                b8e2c1g8h4
                """
        )

    // White's exact scores:
    // a8: -16, c4: -16,
    // a6: -20, a7: -34
    #expect(
        square == "a8"
            || square == "c4"
    )
}

@Test
func exactPlayerReportsAnalysis() throws {
    let game = try Game(
        replaying:
            """
            f5f4d3f6g5d6g7c4d7c2e3h8
            c3d2b4f3f2h6g4d8c7h4e6e7
            f8c5e1b8f7b2c8e2a8g6d1a3
            b3b1h7g8a2e8b5a4c6b6b7a7
            a5a1g2g3c1
            """
    )

    let analysis =
        try ExactPlayer()
        .analyze(in: game)

    #expect(
        try Board.square(analysis.move)
            == "a6"
    )
    #expect(analysis.score == 28)
    #expect(analysis.nodeCount > 1)
    #expect(analysis.cutoffCount > 0)
}

@Test
func initialPositionHasSixtyEmptySquares() {
    #expect(
        Board.initialPosition
            .emptySquareCount == 60
    )
}

@Test
func exactPlayerUsesTranspositionTable() throws {
    let game = try Game(
        replaying:
            """
            c4e3f3c3e6e7c2g3d3b2f7g7
            f4f5a2b3d6c6d7e8g5f6h2e2
            f8h6a4a3d8h3h5a1e1g8g4d2
            h4g6b4b5b7d1c5c8h8h7c1b1
            """
    )

    let analysis =
        try ExactPlayer()
            .analyze(in: game)

    #expect(
        try Board.square(analysis.move)
            == "g2"
    )
    #expect(analysis.score == -24)
    #expect(
        analysis.transpositionCount > 0
    )
    #expect(
        analysis.transpositionHitCount > 0
    )
}
