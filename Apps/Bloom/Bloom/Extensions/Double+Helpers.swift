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
    let feet = Int((totalInches / 12).rounded(.towardZero))
    let inches = Int((totalInches.truncatingRemainder(dividingBy: 12)).rounded())
    return (feet, inches)
  }

  static func from(feet: Int, inches: Int) -> Double {
    Double(feet) * 30.4 + Double(inches) * 2.54
  }
}
