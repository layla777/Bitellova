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
