//
//  MCTS.swift
//  Bitellova
//
//  Created by IDEGUTI Masaya on 2026/08/26.
//

import Bitellova
import Foundation

struct Edge {
    let move: UInt64
    var visits = 0
    var valueSum = 0.0

    func uctScore(
        parentVisits: Int,
        explorationConstant: Double
    ) -> Double {
        guard visits > 0 else {
            return .infinity
        }

        precondition(parentVisits > 0)
        precondition(explorationConstant >= 0)

        let averageValue =
            valueSum / Double(visits)

        let exploration =
            explorationConstant
            * sqrt(
                log(Double(parentVisits))
                    / Double(visits)
            )

        return averageValue + exploration
    }
}

struct Node {
    let board: Board
    var visits = 0
    var valueSum = 0.0
    var edges: [Edge]

    init(board: Board) {
        var mutableBoard = board
        var remainingMoves =
            mutableBoard.legalMoves

        var edges: [Edge] = []

        while remainingMoves != 0 {
            let move =
                remainingMoves
                & ~(remainingMoves &- 1)

            edges.append(
                Edge(move: move)
            )

            remainingMoves &=
                remainingMoves &- 1
        }

        if edges.isEmpty && mutableBoard.isPass {
            // A zero move represents a pass.
            edges.append(
                Edge(move: 0)
            )
        }

        self.board = board
        self.edges = edges
    }

    func selectedEdgeIndex(
        explorationConstant: Double
    ) -> Int? {
        precondition(
            explorationConstant >= 0
        )

        guard
            let firstIndex =
                edges.indices.first
        else {
            return nil
        }

        var selectedIndex = firstIndex

        var selectedScore =
            edges[firstIndex].uctScore(
                parentVisits: visits,
                explorationConstant:
                    explorationConstant
            )

        for index in edges.indices.dropFirst() {
            let score =
                edges[index].uctScore(
                    parentVisits: visits,
                    explorationConstant:
                        explorationConstant
                )

            if score > selectedScore {
                selectedIndex = index
                selectedScore = score
            }
        }

        return selectedIndex
    }
}

struct MCTS {
    static let defaultExplorationConstant = 2.0.squareRoot()

    let explorationConstant: Double

    private var nodes: [Board: Node] = [:]

    init(
        explorationConstant: Double = defaultExplorationConstant
    ) {
        precondition(
            explorationConstant >= 0
        )

        self.explorationConstant = explorationConstant

    }

    var nodeCount: Int {
        nodes.count
    }

    @discardableResult
    mutating func ensureNode(
        for board: Board
    ) -> (
        board: Board,
        symmetry: BoardSymmetry
    ) {
        let canonical =
            board.canonicalized()

        if nodes[canonical.board] == nil {
            nodes[canonical.board] = Node(
                board: canonical.board
            )
        }

        return canonical
    }

    mutating func selectedMove(
        for board: Board
    ) -> UInt64? {
        let canonical =
            ensureNode(for: board)

        guard
            let node =
                nodes[canonical.board],
            let edgeIndex =
                node.selectedEdgeIndex(
                    explorationConstant:
                        explorationConstant
                )
        else {
            return nil
        }

        let canonicalMove =
            node.edges[edgeIndex].move

        return canonical.symmetry
            .inverse
            .transform(canonicalMove)
    }
}
