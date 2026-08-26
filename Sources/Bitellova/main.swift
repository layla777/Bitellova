//
//  main.swift
//
//
//  Created by ideguti masaya on 2026/08/24.
//

import Foundation

let clock = ContinuousClock()
let start = clock.now
let TRIAL = 5000

for _ in 0 ..< TRIAL {
    var game = Game()
    
    while !game.isGameOver {
        if game.isPass {
            game.pass()
            continue
        }
        
        let moves = game.legalMoves
        let move = moves & ~(moves &- 1)
        
        do {
            let position = try Board.square(move)
            try game.play(position)
        } catch {
            print("Error:", error)
            break
        }
    }
}

let elapsed = start.duration(to: clock.now)

print("\(TRIAL) games")
print("Elapsed:", elapsed)
print("Average:", elapsed / TRIAL)
