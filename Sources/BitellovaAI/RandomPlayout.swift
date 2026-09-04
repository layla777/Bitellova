//
//  RandomPlayout.swift
//
//
//  Created by ideguti masaya on 2026/09/02.
//

import Bitellova

package struct RandomPlayout {
    package init() {}

    package func outcome<R: RandomNumberGenerator>(
        from initialGame: Game,
        using generator: inout R
    ) throws -> Game.Outcome {
        var game = initialGame
        let randomPlayer = RandomPlayer()

        var plyCount = 0

        while !game.isGameOver {
            plyCount += 1

            precondition(
                plyCount <= 128,
                "Random playout appears not to terminate"
            )

            if game.isPass {
                try game.pass()
                continue
            }

            let move =
                randomPlayer.selectMove(
                    from: game.legalMoves,
                    using: &generator
                )

            try game.play(move)
        }

        guard let outcome = game.outcome else {
            preconditionFailure(
                "Random playout did not reach game over"
            )
        }

        return outcome
    }
}
