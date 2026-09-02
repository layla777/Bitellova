//
//  OutcomeReward.swift
//
//
//  Created by ideguti masaya on 2026/09/02.
//

import Bitellova

extension Game.Outcome {
    func reward(
        for player: Player
    ) -> Int {
        switch (self, player) {
        case (.blackWin, .black),
            (.whiteWin, .white):
            return 1

        case (.draw, _):
            return 0

        default:
            return -1
        }
    }
}
