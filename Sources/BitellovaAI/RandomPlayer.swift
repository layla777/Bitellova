//
//  RandomPlayer.swift
//
//
//  Created by ideguti masaya on 2026/09/01.
//

package struct RandomPlayer {
    package init() {}

    package func selectMove<R: RandomNumberGenerator>(
        from legalMoves: UInt64,
        using generator: inout R
    ) -> UInt64 {
        precondition(legalMoves != 0)

        var remaining = legalMoves
        var index = Int.random(
            in: 0..<legalMoves.nonzeroBitCount,
            using: &generator
        )

        while index > 0 {
            remaining &= remaining &- 1
            index -= 1
        }

        return remaining & ~(remaining &- 1)
    }
}
