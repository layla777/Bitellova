//
//  main.swift
//  
//
//  Created by ideguti masaya on 2026/08/24.
//

import Foundation

var board = Board.initialPosition

print(board)

do {
    board = try board.played("c4")
    print(board)
} catch {
    print("Error:", error)
}
