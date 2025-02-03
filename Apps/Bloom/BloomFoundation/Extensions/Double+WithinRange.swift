//
//  Double+WithinRange.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-02.
//

import Foundation

public extension Double {

  func isWithinRange(of value: Double, precision: Double) -> Bool {
    guard value != 0 else {
      return abs(self) <= precision // If value is 0, check if self is within precision of 0
    }

    let difference = abs(self - value) / abs(value)
    return difference <= precision
  }
}
