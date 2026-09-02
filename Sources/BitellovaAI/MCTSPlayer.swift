//
//  MCTSPlayer.swift
//
//
//  Created by ideguti masaya on 2026/09/02.
//

import Bitellova

package struct MCTSPlayer {
    private let iterationCount: Int
    private let explorationConstant: Double

    package init(
        iterationCount: Int
    ) {
        self.init(
            iterationCount:
                iterationCount,
            explorationConstant:
                MCTS.defaultExplorationConstant
        )
    }

    package init(
        iterationCount: Int,
        explorationConstant: Double
    ) {
        precondition(iterationCount > 0)
        precondition(
            explorationConstant >= 0
        )

        self.iterationCount =
            iterationCount

        self.explorationConstant =
            explorationConstant
    }

    package func selectMove<
        R: RandomNumberGenerator
    >(
        in game: Game,
        using generator: inout R
    ) throws -> UInt64 {
        var board = game.board

        precondition(
            board.legalMoves != 0
        )

        var mcts = MCTS(
            explorationConstant:
                explorationConstant
        )

        for _ in 0..<iterationCount {
            try mcts.runIteration(
                from: board,
                using: &generator
            )
        }

        guard
            let move =
                mcts.bestMove(for: board)
        else {
            preconditionFailure(
                "MCTS produced no move"
            )
        }

        precondition(move != 0)

        return move
    }
}
