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
    private var nodes: [Board: Node] = [:]

    var nodeCount: Int {
        nodes.count
    }

    mutating func ensureNode(
        for board: Board
    ) {
        let canonicalBoard =
            board.canonicalized().board

        guard nodes[canonicalBoard] == nil else {
            return
        }

        nodes[canonicalBoard] = Node(
            board: canonicalBoard
        )
    }
}
