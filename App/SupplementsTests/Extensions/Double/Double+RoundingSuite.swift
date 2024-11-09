//
//  Double+RoundingSuite.swift
//  SupplementsTests
//
//  Created by Mark DiFranco on 2024-10-03.
//

import Testing
@testable import Supplements

struct Double_RoundingSuite {

    @Test(
        arguments: [
            (11, 10),
            (15, 15),
            (18, 20),
            (17, 15),
            (6, 6),
            (5.6, 6),
            (843, 840),
            (1234, 1200),
            (19876, 19900),
            (198765, 198800)
        ]
    )
    func rounding(input: Double, expectedOutput: Double) async throws {
        let result = input.roundedToNiceNumber()

        #expect(result.isWithinRange(of: expectedOutput, precision: 0.01))
    }
}
