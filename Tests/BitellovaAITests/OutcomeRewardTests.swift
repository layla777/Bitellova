//
//  OutcomeRewardTests.swift
//
//
//  Created by ideguti masaya on 2026/09/02.
//

import Testing

@testable import Bitellova
@testable import BitellovaAI

@Test
func outcomeRewardUsesRequestedPlayersPerspective() {
    #expect(
        Game.Outcome.blackWin.reward(
            for: .black
        ) == 1
    )

    #expect(
        Game.Outcome.blackWin.reward(
            for: .white
        ) == -1
    )

    #expect(
        Game.Outcome.whiteWin.reward(
            for: .white
        ) == 1
    )

    #expect(
        Game.Outcome.whiteWin.reward(
            for: .black
        ) == -1
    )

    #expect(
        Game.Outcome.draw.reward(
            for: .black
        ) == 0
    )

    #expect(
        Game.Outcome.draw.reward(
            for: .white
        ) == 0
    )
}
