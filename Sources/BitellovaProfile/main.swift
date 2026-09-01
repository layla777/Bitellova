//
//  main.swift
//
//
//  Created by ideguti masaya on 2026/09/01.
//

import Bitellova

@inline(never)
func playOneGame() throws {
    var game = Game()

    while !game.isGameOver {
        if game.isPass {
            try game.pass()
            continue
        }

        let moves = game.legalMoves
        let move = UInt64(1) << (63 - moves.leadingZeroBitCount)

        try game.play(move)
    }
}

let trialCount = 1_000_000
let clock = ContinuousClock()
let start = clock.now

for _ in 0..<trialCount {
    try playOneGame()
}

let elapsed = start.duration(to: clock.now)

print("\(trialCount) games")
print("Elapsed:", elapsed)
print("Average:", elapsed / trialCount)
