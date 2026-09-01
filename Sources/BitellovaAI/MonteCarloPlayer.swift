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

                try playRandomlyToEnd(
                    game: &rollout,
                    using: &generator
                )

                guard let outcome = rollout.outcome else {
                    preconditionFailure(
                        "Random rollout did not reach game over"
                    )
                }

                totalReward += reward(
                    for: outcome,
                    from: rootPlayer
                )
            }

            if totalReward > bestScore {
                bestScore = totalReward
                bestMove = move
            }
        }

        return bestMove
    }

    private func playRandomlyToEnd<R: RandomNumberGenerator>(
        game: inout Game,
        using generator: inout R
    ) throws {
        let randomPlayer = RandomPlayer()

        while !game.isGameOver {
            if game.isPass {
                try game.pass()
                continue
            }

            let legalMoves = game.legalMoves
            let move = randomPlayer.selectMove(
                from: legalMoves,
                using: &generator
            )

            try game.play(move)
        }
    }

    private func reward(
        for outcome: Game.Outcome,
        from player: Player
    ) -> Int {
        switch (outcome, player) {
        case (.blackWin, .black), (.whiteWin, .white):
            return 1

        case (.draw, _):
            return 0

        default:
            return -1
        }
    }
}
