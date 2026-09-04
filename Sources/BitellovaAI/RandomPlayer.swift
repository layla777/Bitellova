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

        let moveCount =
            UInt64(legalMoves.nonzeroBitCount)

        // Lemire's nearly divisionless method,
        // specialized here for UInt64 performance.
        var random =
            generator.next()

        var product =
            random.multipliedFullWidth(
                by: moveCount
            )

        if product.low < moveCount {
            let threshold =
                (0 &- moveCount)
                % moveCount

            while product.low < threshold {
                random =
                    generator.next()

                product =
                    random.multipliedFullWidth(
                        by: moveCount
                    )
            }
        }

        var remaining = legalMoves
        var index = Int(product.high)

        while index > 0 {
            remaining &=
                remaining &- 1

            index -= 1
        }

        return remaining
            & ~(remaining &- 1)
    }
}
