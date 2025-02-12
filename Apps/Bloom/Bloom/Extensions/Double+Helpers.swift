//
//  Double+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-27.
//

import Foundation

extension Double {

  var asCGFloat: CGFloat {
    CGFloat(self)
  }

  func toFeetInches() -> (Int, Int) {
    let totalInches = self / 2.54
    var feet = Int((totalInches / 12).rounded(.towardZero))
    var inches = Int((totalInches.truncatingRemainder(dividingBy: 12)).rounded())

    // Correcting an invalid case due to rounding..
    if inches == 12 {
      feet += 1
      inches = 0
    }

    return (feet, inches)
  }

  static func from(feet: Int, inches: Int) -> Double {
    Double(feet) * 30.4 + Double(inches) * 2.54
  }
}
