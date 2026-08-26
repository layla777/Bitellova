//
//  main.swift
//  
//
//  Created by ideguti masaya on 2026/08/24.
//

import Foundation

var game = Game()

print(game.board)

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
        print(game.board)
    } catch {
        print("Error:", error)
        break
    }
}

