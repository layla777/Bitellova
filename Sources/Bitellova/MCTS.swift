//
//  MCTS.swift
//  Bitellova
//
//  Created by IDEGUTI Masaya on 2026/08/26.
//

struct Edge {
    let move: UInt64
    var visits = 0
    var valueSum = 0.0
}

struct Node {
    let board: Board
    var visits = 0
    var valueSum = 0.0
    var edges: [Edge] = []
}

struct MCTS {
    private var nodes: [Board: Node] = [:]
}
