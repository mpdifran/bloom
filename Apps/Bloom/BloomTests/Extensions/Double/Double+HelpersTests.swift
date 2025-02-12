//
//  Double+HelpersTests.swift
//  BloomTests
//
//  Created by Mark DiFranco on 2025-02-12.
//

import Testing
@testable import Bloom

struct Double_HelpersTestSuite {

  @Test(arguments: [
    (185, 6, 1),
    (182, 6, 0),
    (180, 5, 11),
    (182.4, 6, 0)
  ])
  func toFeetInches(
    input: Double,
    expectedFeet: Int,
    expectedInches: Int
  ) {
    let (feet, inches) = input.toFeetInches()

    #expect(feet == expectedFeet)
    #expect(inches == expectedInches)
  }

  @Test(arguments: [
    (6, 1, 185),
    (6, 0, 182.4),
    (5, 11, 180)
  ])
  func fromFeetInches(
    inputFeet: Int,
    inputInches: Int,
    expectedCM: Double
  ) {
    let cm = Double.from(feet: inputFeet, inches: inputInches)

    #expect(cm.isWithinRange(of: expectedCM, precision: 0.1))
  }
}
