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

//func randomMove(from moves: UInt64) -> UInt64 {
//    precondition(moves != 0)
//
//    var remaining = moves
//    var index = Int.random(in: 0..<moves.nonzeroBitCount)
//
//    while index > 0 {
//        // Remove the least significant set bit.
//        remaining &= remaining &- 1
//        index -= 1
//    }
//
//    // Extract the selected set bit.
//    return remaining & ~(remaining &- 1)
//}
//
//let trialCount = 50_000
//let clock = ContinuousClock()
//let start = clock.now
//
//for gameNumber in 1...trialCount {
//    var game = Game()
//
//    while !game.isGameOver {
//        if game.isPass {
//            game.pass()
//            continue
//        }
//
//        let move = randomMove(from: game.legalMoves)
//
//        do {
//            let position = try Board.square(move)
//            try game.play(position)
//        } catch {
//            fatalError(
//                "Game \(gameNumber) failed at \(String(move, radix: 16)): \(error)"
//            )
//        }
//    }
//
//    if gameNumber.isMultiple(of: 5_000) {
//        print("\(gameNumber) / \(trialCount) games verified")
//    }
//}
//
//let elapsed = start.duration(to: clock.now)
//
//print("\n\(trialCount) random games verified")
//print("Elapsed (not a benchmark):", elapsed)
