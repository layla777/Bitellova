//
//  MonteCarloPlayer.swift
//
//
//  Created by ideguti masaya on 2026/09/01.
//

import Bitellova

package struct MonteCarloPlayer {
    private let playoutsPerMove: Int

    package init(playoutsPerMove: Int) {
        precondition(playoutsPerMove > 0)
        self.playoutsPerMove = playoutsPerMove
    }

    package func selectMove<R: RandomNumberGenerator>(
        in game: Game,
        using generator: inout R
    ) throws -> UInt64 {
        let randomPlayout = RandomPlayout()

        let rootPlayer = game.currentPlayer

        var gameForMoves = game
        let legalMoves = gameForMoves.legalMoves

        precondition(legalMoves != 0)

        var remainingMoves = legalMoves
        var bestMove: UInt64 = 0
        var bestScore = Int.min

        while remainingMoves != 0 {
            let move =
                remainingMoves
                & ~(remainingMoves &- 1)

            remainingMoves &= remainingMoves &- 1

            var totalReward = 0

            for _ in 0..<playoutsPerMove {
                var rollout = game
                try rollout.play(move)

                let outcome =
                    try randomPlayout.outcome(
                        from: rollout,
                        using: &generator
                    )

                totalReward += outcome.reward(
                    for: rootPlayer
                )
            }

            if totalReward > bestScore {
                bestScore = totalReward
                bestMove = move
            }
        }

        return bestMove
    }
}
