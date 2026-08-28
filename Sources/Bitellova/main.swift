//
//  main.swift
//
//
//  Created by ideguti masaya on 2026/08/24.
//

import Foundation

let clock = ContinuousClock()
let start = clock.now
let TRIAL = 500_000

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


//var game = Game()
//print(game.board)
//
//try! game.play("f5")
//print(game.board)


//var game = Game()
//print(game.board)
//
//while !game.isGameOver {
//    if game.isPass {
//        game.pass()
//        print(game.board)
//        print("Passed.\n")
//        continue
//    }
//
//    let moves = game.legalMoves
//    let move = moves & ~(moves &- 1)
//
//    do {
//        let position = try Board.square(move)
//        try game.play(position)
//        print(game.board)
//        print(position)
//    } catch {
//        print("Error:", error)
//        break
//    }
//}
