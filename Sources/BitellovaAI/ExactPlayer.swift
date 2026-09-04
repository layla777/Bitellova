//
//  ExactPlayer.swift
//
//
//  Created by ideguti masaya on 2026/09/04.
//

import Bitellova

package struct ExactPlayer {
    package struct Analysis {
        package let move: UInt64
        package let score: Int
        package let nodeCount: Int
        package let cutoffCount: Int
        package let transpositionCount: Int
        package let transpositionHitCount: Int
    }

    private enum TranspositionBound {
        case exact
        case lower
        case upper
    }

    private struct TranspositionEntry {
        let score: Int
        let bound: TranspositionBound
    }

    private typealias TranspositionTable =
        [Board: TranspositionEntry]

    private struct SearchStatistics {
        // The root position is also a node.
        var nodeCount = 1
        var cutoffCount = 0
        var transpositionHitCount = 0
    }

    private struct Child {
        let move: UInt64
        let board: Board
        let opponentMobility: Int
    }

    private static let negativeInfinity = -65
    private static let positiveInfinity = 65

    private static let
        mobilityOrderingMinimumEmptySquareCount = 6

    private static let
        transpositionMinimumEmptySquareCount = 8

    package init() {}

    package func selectMove(
        in game: Game
    ) throws -> UInt64 {
        let analysis =
            try analyze(in: game)

        return analysis.move
    }

    package func analyze(
        in game: Game
    ) throws -> Analysis {
        let board = game.board

        let children =
            try orderedChildren(of: board)

        precondition(
            !children.isEmpty
        )

        var bestMove: UInt64 = 0
        var bestScore =
            Self.negativeInfinity

        var alpha =
            Self.negativeInfinity

        let beta =
            Self.positiveInfinity

        var statistics =
            SearchStatistics()

        var transpositionTable:
            TranspositionTable = [:]

        for child in children {
            let opponentScore =
                try search(
                    child.board,
                    alpha: -beta,
                    beta: -alpha,
                    statistics: &statistics,
                    transpositionTable:
                        &transpositionTable
                )

            let score = -opponentScore

            if score > bestScore {
                bestScore = score
                bestMove = child.move
            }

            alpha = max(alpha, score)
        }

        precondition(bestMove != 0)

        return Analysis(
            move: bestMove,
            score: bestScore,
            nodeCount:
                statistics.nodeCount,
            cutoffCount:
                statistics.cutoffCount,
            transpositionCount:
                transpositionTable.count,
            transpositionHitCount:
                statistics
                    .transpositionHitCount
        )
    }

    private func orderedChildren(
        of position: Board
    ) throws -> [Child] {
        var board = position

        var remainingMoves =
            board.legalMoves

        let shouldOrderByMobility =
            board.emptySquareCount
            >= Self
                .mobilityOrderingMinimumEmptySquareCount

        var children: [Child] = []

        children.reserveCapacity(
            remainingMoves.nonzeroBitCount
        )

        while remainingMoves != 0 {
            let move =
                remainingMoves
                & ~(remainingMoves &- 1)

            remainingMoves &=
                remainingMoves &- 1

            var child =
                try board.playedBoard(move)

            let opponentMobility: Int

            if shouldOrderByMobility {
                opponentMobility =
                    child.legalMoves
                        .nonzeroBitCount
            } else {
                opponentMobility = 0
            }

            children.append(
                Child(
                    move: move,
                    board: child,
                    opponentMobility:
                        opponentMobility
                )
            )
        }

        if shouldOrderByMobility {
            children.sort {
                if $0.opponentMobility
                    != $1.opponentMobility
                {
                    return $0.opponentMobility
                        < $1.opponentMobility
                }

                return $0.move < $1.move
            }
        }

        return children
    }

    private func search(
        _ position: Board,
        alpha: Int,
        beta: Int,
        statistics: inout SearchStatistics,
        transpositionTable:
            inout TranspositionTable
    ) throws -> Int {
        statistics.nodeCount += 1

        var board = position

        let originalAlpha = alpha
        let originalBeta = beta

        var currentAlpha = alpha
        var currentBeta = beta

        let usesTranspositionTable =
            board.emptySquareCount
            >= Self
                .transpositionMinimumEmptySquareCount

        if usesTranspositionTable,
            let entry =
                transpositionTable[board]
        {
            statistics
                .transpositionHitCount += 1

            switch entry.bound {
            case .exact:
                return entry.score

            case .lower:
                currentAlpha = max(
                    currentAlpha,
                    entry.score
                )

            case .upper:
                currentBeta = min(
                    currentBeta,
                    entry.score
                )
            }

            if currentAlpha >= currentBeta {
                return entry.score
            }
        }

        if board.isGameOver {
            let score =
                finalScore(for: board)

            if usesTranspositionTable {
                transpositionTable[board] =
                    TranspositionEntry(
                        score: score,
                        bound: .exact
                    )
            }

            return score
        }

        if board.isPass {
            let opponentScore =
                try search(
                    board.passedBoard(),
                    alpha: -currentBeta,
                    beta: -currentAlpha,
                    statistics: &statistics,
                    transpositionTable:
                        &transpositionTable
                )

            let score = -opponentScore

            storeTransposition(
                for: board,
                score: score,
                alpha: originalAlpha,
                beta: originalBeta,
                in: &transpositionTable
            )

            return score
        }

        let score: Int

        if board.emptySquareCount
            < Self
                .mobilityOrderingMinimumEmptySquareCount
        {
            score =
                try searchInBitOrder(
                    board,
                    alpha: currentAlpha,
                    beta: currentBeta,
                    statistics: &statistics,
                    transpositionTable:
                        &transpositionTable
                )
        } else {
            let children =
                try orderedChildren(
                    of: board
                )

            var bestScore =
                Self.negativeInfinity

            for child in children {
                let opponentScore =
                    try search(
                        child.board,
                        alpha: -currentBeta,
                        beta: -currentAlpha,
                        statistics:
                            &statistics,
                        transpositionTable:
                            &transpositionTable
                    )

                let childScore =
                    -opponentScore

                bestScore = max(
                    bestScore,
                    childScore
                )

                currentAlpha = max(
                    currentAlpha,
                    childScore
                )

                if currentAlpha
                    >= currentBeta
                {
                    statistics
                        .cutoffCount += 1
                    break
                }
            }

            score = bestScore
        }

        storeTransposition(
            for: board,
            score: score,
            alpha: originalAlpha,
            beta: originalBeta,
            in: &transpositionTable
        )

        return score
    }

    private func searchInBitOrder(
        _ position: Board,
        alpha: Int,
        beta: Int,
        statistics: inout SearchStatistics,
        transpositionTable:
            inout TranspositionTable
    ) throws -> Int {
        var board = position

        var remainingMoves =
            board.legalMoves

        var bestScore =
            Self.negativeInfinity

        var currentAlpha = alpha

        while remainingMoves != 0 {
            let move =
                remainingMoves
                & ~(remainingMoves &- 1)

            remainingMoves &=
                remainingMoves &- 1

            let child =
                try board.playedBoard(move)

            let opponentScore =
                try search(
                    child,
                    alpha: -beta,
                    beta: -currentAlpha,
                    statistics: &statistics,
                    transpositionTable:
                        &transpositionTable
                )

            let score = -opponentScore

            bestScore = max(
                bestScore,
                score
            )

            currentAlpha = max(
                currentAlpha,
                score
            )

            if currentAlpha >= beta {
                statistics.cutoffCount += 1
                break
            }
        }

        return bestScore
    }

    private func storeTransposition(
        for board: Board,
        score: Int,
        alpha: Int,
        beta: Int,
        in transpositionTable:
            inout TranspositionTable
    ) {
        guard
            board.emptySquareCount
                >= Self
                    .transpositionMinimumEmptySquareCount
        else {
            return
        }

        let bound: TranspositionBound

        if score <= alpha {
            bound = .upper
        } else if score >= beta {
            bound = .lower
        } else {
            bound = .exact
        }

        transpositionTable[board] =
            TranspositionEntry(
                score: score,
                bound: bound
            )
    }

    private func finalScore(
        for board: Board
    ) -> Int {
        guard
            let score = board.finalScore
        else {
            preconditionFailure(
                "Exact search reached a non-terminal board without legal moves"
            )
        }

        let blackDifference =
            score.black - score.white

        switch board.turn {
        case .black:
            return blackDifference

        case .white:
            return -blackDifference
        }
    }
}
