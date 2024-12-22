//
//  Double+Conversion.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-22.
//

import Foundation

extension Double {

  /// Assumes the receiver is in grams.
  var mg: Double {
    self * 1000
  }
}
