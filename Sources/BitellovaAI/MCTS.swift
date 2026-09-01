//
//  MCTS.swift
//  Bitellova
//
//  Created by IDEGUTI Masaya on 2026/08/26.
//

import Bitellova

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

    var nodeCount: Int {
        nodes.count
    }

    mutating func ensureNode(
        for board: Board
    ) {
        let canonicalBoard =
            board.canonicalized().board

        guard nodes[canonicalBoard] == nil else {
            return
        }

        nodes[canonicalBoard] = Node(
            board: canonicalBoard
        )
    }
}
