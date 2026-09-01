//
//  SplitMix64.swift
//
//
//  Created by ideguti masaya on 2026/09/01.
//

package struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    package init(seed: UInt64) {
        state = seed
    }

    package mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15

        var value = state
        value =
            (value ^ (value >> 30))
            &* 0xBF58_476D_1CE4_E5B9
        value =
            (value ^ (value >> 27))
            &* 0x94D0_49BB_1331_11EB

        return value ^ (value >> 31)
    }
}
