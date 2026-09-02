//
//  MCTSTests.swift
//
//
//  Created by ideguti masaya on 2026/09/02.
//

import Foundation
import Testing

@testable import Bitellova
@testable import BitellovaAI

@Test
func symmetricBoardsShareOneMCTSNode() throws {
    var game = Game()

    try game.play("d3")
    try game.play("c3")

    let board = game.board
    let rotatedBoard = board.transformed(
        by: .rotate90Clockwise
    )

    var mcts = MCTS()

    mcts.ensureNode(for: board)
    mcts.ensureNode(for: rotatedBoard)

    #expect(mcts.nodeCount == 1)
}

@Test
func newNodeHasOneUnvisitedEdgePerLegalMove() {
    var board = Board.initialPosition
    let legalMoves = board.legalMoves

    let node = Node(board: board)

    let edgeMoves = node.edges.reduce(UInt64(0)) {
        $0 | $1.move
    }

    #expect(node.edges.count == legalMoves.nonzeroBitCount)
    #expect(edgeMoves == legalMoves)

    #expect(
        node.edges.allSatisfy {
            $0.visits == 0
                && $0.valueSum == 0
        }
    )
}

@Test
func unvisitedEdgeHasInfiniteUCTScore() {
    let edge = Edge(move: 1)

    let score = edge.uctScore(
        parentVisits: 1,
        explorationConstant: 1.5
    )

    #expect(score == .infinity)
}

@Test
func visitedEdgeUCTScoreCombinesValueAndExploration() {
    var edge = Edge(move: 1)
    edge.visits = 4
    edge.valueSum = 2.0

    let score = edge.uctScore(
        parentVisits: 16,
        explorationConstant: 1.5
    )

    let expected =
        0.5
        + 1.5
        * sqrt(log(16.0) / 4.0)

    #expect(
        abs(score - expected) < 1e-12
    )
}

@Test
func nodeSelectsItsOnlyUnvisitedEdge() {
    var node = Node(
        board: .initialPosition
    )

    for index in node.edges.indices {
        node.edges[index].visits = 1
    }

    let unvisitedIndex = 2
    node.edges[unvisitedIndex].visits = 0
    node.visits =
        node.edges.count - 1

    let selectedIndex =
        node.selectedEdgeIndex(
            explorationConstant: 1.5
        )

    #expect(
        selectedIndex == unvisitedIndex
    )
}

@Test
func nodeSelectsEdgeWithHighestAverageWhenExplorationIsZero() {
    var node = Node(
        board: .initialPosition
    )

    for index in node.edges.indices {
        node.edges[index].visits = 1
        node.edges[index].valueSum = 0
    }

    let strongestIndex = 1
    node.edges[strongestIndex].valueSum =
        0.75

    node.visits = node.edges.count

    let selectedIndex =
        node.selectedEdgeIndex(
            explorationConstant: 0
        )

    #expect(
        selectedIndex == strongestIndex
    )
}

@Test
func mctsSelectsLegalMoveInOriginalOrientation() {
    var board = Board.initialPosition
    let legalMoves = board.legalMoves

    var mcts = MCTS(
        explorationConstant: 1.5
    )

    let selectedMove =
        mcts.selectedMove(for: board)

    #expect(
        selectedMove?.nonzeroBitCount == 1
    )

    #expect(
        selectedMove.map {
            legalMoves & $0 != 0
        } == true
    )
}

@Test
func passNodeHasSinglePassEdge() {
    let board = Board(
        // Black: b1
        black:
            0b01000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        // White: a1
        white:
            0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        turn: .black
    )

    let node = Node(board: board)

    #expect(node.edges.count == 1)
    #expect(node.edges.first?.move == 0)
}

@Test
func expandingInitialNodeCreatesCanonicalChild() throws {
    let board = Board.initialPosition

    var mcts = MCTS()
    mcts.ensureNode(for: board)

    #expect(mcts.nodeCount == 1)

    let child =
        try mcts.expand(from: board)

    #expect(child != nil)
    #expect(mcts.nodeCount == 2)

    if let child {
        #expect(
            child
                == child.canonicalized().board
        )
    }
}

@Test
func backpropagationUpdatesNodeAndSelectedEdge() throws {
    let board = Board.initialPosition

    var mcts = MCTS()

    let canonical =
        mcts.ensureNode(for: board)

    let path = [
        MCTS.PathEntry(
            canonicalBoard: canonical.board,
            edgeIndex: 0
        )
    ]

    mcts.backpropagate(
        outcome: .blackWin,
        through: path
    )

    let updatedNode =
        try #require(
            mcts.node(for: board)
        )

    #expect(updatedNode.visits == 1)
    #expect(updatedNode.valueSum == 1.0)

    #expect(
        updatedNode.edges[0].visits == 1
    )

    #expect(
        updatedNode.edges[0].valueSum
            == 1.0
    )
}

@Test
func backpropagationUsesEachNodesPlayerPerspective() throws {
    let rootBoard =
        Board.initialPosition

    var mcts = MCTS()

    let canonicalRoot =
        mcts.ensureNode(
            for: rootBoard
        ).board

    let rootNode =
        try #require(
            mcts.node(
                for: canonicalRoot
            )
        )

    let edgeIndex =
        try #require(
            rootNode.edges.indices.first
        )

    let move =
        rootNode.edges[edgeIndex].move

    let childBoard =
        try canonicalRoot
        .playedBoard(move)
        .canonicalized()
        .board

    mcts.ensureNode(
        for: childBoard
    )

    let path = [
        MCTS.PathEntry(
            canonicalBoard:
                canonicalRoot,
            edgeIndex: edgeIndex
        ),

        MCTS.PathEntry(
            canonicalBoard:
                childBoard,
            edgeIndex: nil
        ),
    ]

    mcts.backpropagate(
        outcome: .blackWin,
        through: path
    )

    let updatedRoot =
        try #require(
            mcts.node(
                for: canonicalRoot
            )
        )

    let updatedChild =
        try #require(
            mcts.node(
                for: childBoard
            )
        )

    #expect(updatedRoot.visits == 1)
    #expect(updatedRoot.valueSum == 1.0)

    #expect(
        updatedRoot.edges[edgeIndex]
            .visits == 1
    )

    #expect(
        updatedRoot.edges[edgeIndex]
            .valueSum == 1.0
    )

    #expect(updatedChild.visits == 1)
    #expect(updatedChild.valueSum == -1.0)

    #expect(
        updatedChild.edges.allSatisfy {
            $0.visits == 0
        }
    )
}

@Test
func oneMCTSIterationVisitsRootAndOneRootEdge() throws {
    let board =
        Board.initialPosition

    var generator =
        SplitMix64(seed: 42)

    var mcts = MCTS()

    try mcts.runIteration(
        from: board,
        using: &generator
    )

    let rootNode =
        try #require(
            mcts.node(for: board)
        )

    #expect(rootNode.visits == 1)

    let totalEdgeVisits =
        rootNode.edges.reduce(0) {
            $0 + $1.visits
        }

    #expect(totalEdgeVisits == 1)
    #expect(mcts.nodeCount >= 2)

    #expect(
        [-1.0, 0.0, 1.0]
            .contains(rootNode.valueSum)
    )
}
