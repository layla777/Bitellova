//
//  MCTS.swift
//  Bitellova
//
//  Created by ideguti masaya on 2026/08/26.
//

import Bitellova
import Foundation

struct Edge {
    let move: UInt64
    var visits = 0
    var valueSum = 0.0
    var child: Node? = nil

    func uctScore(
        parentVisits: Int,
        explorationConstant: Double
    ) -> Double {
        guard visits > 0 else {
            return .infinity
        }

        precondition(parentVisits > 0)
        precondition(parentVisits >= visits)
        precondition(explorationConstant >= 0)

        return uctScore(
            parentLog:
                log(Double(parentVisits)),
            explorationConstant:
                explorationConstant
        )
    }

    func uctScore(
        parentLog: Double,
        explorationConstant: Double
    ) -> Double {
        precondition(visits > 0)
        precondition(parentLog >= 0)
        precondition(explorationConstant >= 0)

        let averageValue =
            valueSum / Double(visits)

        let exploration =
            explorationConstant
            * sqrt(
                parentLog
                    / Double(visits)
            )

        return averageValue + exploration
    }
}

final class Node {
    let board: Board
    var visits = 0
    var valueSum = 0.0
    var edges: [Edge]

    init(board: Board) {
        var mutableBoard = board
        var remainingMoves =
            mutableBoard.legalMoves

        var edges: [Edge] = []

        edges.reserveCapacity(
            remainingMoves.nonzeroBitCount
        )

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

        if edges.isEmpty
            && !mutableBoard.isGameOver
            && mutableBoard.isPass
        {
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

        guard !edges.isEmpty else {
            return nil
        }

        // An unvisited edge always has an infinite UCT score.
        // Returning the first one preserves the existing tie-breaking order.
        for index in edges.indices {
            if edges[index].visits == 0 {
                return index
            }
        }

        precondition(visits > 0)

        let parentLog =
            log(Double(visits))

        var selectedIndex =
            edges.startIndex

        var selectedScore =
            edges[selectedIndex].uctScore(
                parentLog: parentLog,
                explorationConstant:
                    explorationConstant
            )

        for index in edges.indices.dropFirst() {
            let score =
                edges[index].uctScore(
                    parentLog: parentLog,
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

    func mostVisitedEdgeIndex() -> Int? {
        guard
            let firstIndex =
                edges.indices.first
        else {
            return nil
        }

        var bestIndex = firstIndex

        for index in edges.indices.dropFirst() {
            if edges[index].visits
                > edges[bestIndex].visits
            {
                bestIndex = index
            }
        }

        guard edges[bestIndex].visits > 0 else {
            return nil
        }

        return bestIndex
    }
}

struct MCTS {
    struct PathEntry {
        let node: Node
        let edgeIndex: Int?
    }

    static let defaultExplorationConstant =
        2.0.squareRoot()

    let explorationConstant: Double

    private var nodes: [Board: Node] = [:]

    init(
        explorationConstant: Double =
            MCTS.defaultExplorationConstant
    ) {
        precondition(
            explorationConstant >= 0
        )

        self.explorationConstant =
            explorationConstant
    }

    var nodeCount: Int {
        nodes.count
    }

    private mutating func ensuredNode(
        for board: Board
    ) -> (
        node: Node,
        board: Board,
        symmetry: BoardSymmetry
    ) {
        let canonical =
            board.canonicalized()

        if let node =
            nodes[canonical.board]
        {
            return (
                node,
                canonical.board,
                canonical.symmetry
            )
        }

        let node = Node(
            board: canonical.board
        )

        nodes[canonical.board] = node

        return (
            node,
            canonical.board,
            canonical.symmetry
        )
    }

    @discardableResult
    mutating func ensureNode(
        for board: Board
    ) -> (
        board: Board,
        symmetry: BoardSymmetry
    ) {
        let ensured =
            ensuredNode(for: board)

        return (
            ensured.board,
            ensured.symmetry
        )
    }

    mutating func selectedMove(
        for board: Board
    ) -> UInt64? {
        let canonical =
            ensuredNode(for: board)

        guard
            let edgeIndex =
                canonical.node.selectedEdgeIndex(
                    explorationConstant:
                        explorationConstant
                )
        else {
            return nil
        }

        let canonicalMove =
            canonical.node.edges[edgeIndex].move

        return canonical.symmetry
            .inverse
            .transform(canonicalMove)
    }

    mutating func expand(
        from board: Board
    ) throws -> Board? {
        let canonical =
            ensuredNode(for: board)

        guard
            let edgeIndex =
                canonical.node.selectedEdgeIndex(
                    explorationConstant:
                        explorationConstant
                )
        else {
            return nil
        }

        let move =
            canonical.node.edges[edgeIndex].move

        if let child =
            canonical.node.edges[edgeIndex].child
        {
            return child.board
        }

        let childBoard: Board

        if move == 0 {
            childBoard =
                canonical.board.passedBoard()
        } else {
            childBoard =
                try canonical.board.playedBoard(move)
        }

        let canonicalChild =
            ensuredNode(for: childBoard)

        canonical.node.edges[edgeIndex].child =
            canonicalChild.node

        return canonicalChild.board
    }

    func node(
        for board: Board
    ) -> Node? {
        let canonicalBoard =
            board.canonicalized().board

        return nodes[canonicalBoard]
    }

    mutating func backpropagate(
        outcome: Game.Outcome,
        through path: [PathEntry]
    ) {
        for entry in path {
            let node = entry.node

            let reward = Double(
                outcome.reward(
                    for: node.board.turn
                )
            )

            node.visits += 1
            node.valueSum += reward

            if let edgeIndex =
                entry.edgeIndex
            {
                precondition(
                    node.edges.indices
                        .contains(edgeIndex)
                )

                node.edges[edgeIndex].visits += 1
                node.edges[edgeIndex].valueSum +=
                    reward
            }
        }
    }

    mutating func runIteration<
        R: RandomNumberGenerator
    >(
        from board: Board,
        using generator: inout R
    ) throws {
        let rootNode =
            ensuredNode(for: board).node

        var path: [PathEntry] = []

        try runIteration(
            from: rootNode,
            path: &path,
            using: &generator
        )
    }

    mutating func runIterations<
        R: RandomNumberGenerator
    >(
        count: Int,
        from board: Board,
        using generator: inout R
    ) throws {
        precondition(count > 0)

        nodes.reserveCapacity(
            nodes.count + count + 1
        )

        let rootNode =
            ensuredNode(for: board).node

        var path: [PathEntry] = []
        path.reserveCapacity(16)

        for _ in 0..<count {
            try runIteration(
                from: rootNode,
                path: &path,
                using: &generator
            )
        }
    }

    private mutating func runIteration<
        R: RandomNumberGenerator
    >(
        from rootNode: Node,
        path: inout [PathEntry],
        using generator: inout R
    ) throws {
        path.removeAll(
            keepingCapacity: true
        )

        var currentNode = rootNode

        let randomPlayout =
            RandomPlayout()

        var finalOutcome: Game.Outcome?
        var selectionDepth = 0

        while finalOutcome == nil {
            selectionDepth += 1

            precondition(
                selectionDepth <= 128,
                """
                MCTS selection exceeded 128 nodes \
                at board:
                \(currentNode.board)
                """
            )

            guard
                let edgeIndex =
                    currentNode.selectedEdgeIndex(
                        explorationConstant:
                            explorationConstant
                    )
            else {
                path.append(
                    PathEntry(
                        node: currentNode,
                        edgeIndex: nil
                    )
                )

                var terminalGame =
                    Game(
                        board:
                            currentNode.board
                    )

                guard
                    let outcome =
                        terminalGame.outcome
                else {
                    preconditionFailure(
                        "MCTS node without edges is not terminal"
                    )
                }

                finalOutcome = outcome
                continue
            }

            let edge =
                currentNode.edges[edgeIndex]

            path.append(
                PathEntry(
                    node: currentNode,
                    edgeIndex: edgeIndex
                )
            )

            let childNode: Node

            if let cachedChild = edge.child {
                childNode = cachedChild
            } else {
                let childBoard: Board

                if edge.move == 0 {
                    childBoard =
                        currentNode.board
                        .passedBoard()
                } else {
                    childBoard =
                        try currentNode.board
                        .playedBoard(edge.move)
                }

                childNode =
                    ensuredNode(
                        for: childBoard
                    ).node

                currentNode.edges[edgeIndex].child =
                    childNode
            }

            if edge.visits == 0 {
                path.append(
                    PathEntry(
                        node: childNode,
                        edgeIndex: nil
                    )
                )

                let rolloutGame =
                    Game(
                        board:
                            childNode.board
                    )

                finalOutcome =
                    try randomPlayout.outcome(
                        from: rolloutGame,
                        using: &generator
                    )

                continue
            }

            currentNode = childNode
        }

        guard let finalOutcome else {
            preconditionFailure(
                "MCTS iteration produced no outcome"
            )
        }

        backpropagate(
            outcome: finalOutcome,
            through: path
        )
    }

    func bestMove(
        for board: Board
    ) -> UInt64? {
        let canonical =
            board.canonicalized()

        guard
            let node =
                nodes[canonical.board],
            let edgeIndex =
                node.mostVisitedEdgeIndex()
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
