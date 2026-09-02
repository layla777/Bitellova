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
        precondition(parentVisits >= visits)
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
    struct PathEntry {
        let canonicalBoard: Board
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

    mutating func expand(
        from board: Board
    ) throws -> Board? {
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

        let move =
            node.edges[edgeIndex].move

        let childBoard: Board

        if move == 0 {
            childBoard =
                canonical.board.passedBoard()
        } else {
            childBoard =
                try canonical.board.playedBoard(move)
        }

        let canonicalChild =
            ensureNode(for: childBoard)

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
            guard
                var node =
                    nodes[entry.canonicalBoard]
            else {
                preconditionFailure(
                    "Backpropagation path contains an unknown node"
                )
            }

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

            nodes[entry.canonicalBoard] = node
        }
    }

    mutating func runIteration<
        R: RandomNumberGenerator
    >(
        from board: Board,
        using generator: inout R
    ) throws {
        var path: [PathEntry] = []

        var currentBoard =
            ensureNode(for: board).board

        let randomPlayout =
            RandomPlayout()

        var finalOutcome: Game.Outcome?

        while finalOutcome == nil {
            guard
                let node =
                    nodes[currentBoard]
            else {
                preconditionFailure(
                    "Current MCTS node is missing"
                )
            }

            guard
                let edgeIndex =
                    node.selectedEdgeIndex(
                        explorationConstant:
                            explorationConstant
                    )
            else {
                path.append(
                    PathEntry(
                        canonicalBoard:
                            currentBoard,
                        edgeIndex: nil
                    )
                )

                var terminalGame =
                    Game(board: currentBoard)

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
                node.edges[edgeIndex]

            path.append(
                PathEntry(
                    canonicalBoard:
                        currentBoard,
                    edgeIndex: edgeIndex
                )
            )

            let childBoard: Board

            if edge.move == 0 {
                childBoard =
                    currentBoard.passedBoard()
            } else {
                childBoard =
                    try currentBoard.playedBoard(edge.move)
            }

            let canonicalChild =
                ensureNode(
                    for: childBoard
                ).board

            if edge.visits == 0 {
                path.append(
                    PathEntry(
                        canonicalBoard:
                            canonicalChild,
                        edgeIndex: nil
                    )
                )

                let rolloutGame =
                    Game(
                        board:
                            canonicalChild
                    )

                finalOutcome =
                    try randomPlayout.outcome(
                        from: rolloutGame,
                        using: &generator
                    )

                continue
            }

            currentBoard =
                canonicalChild
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
}
