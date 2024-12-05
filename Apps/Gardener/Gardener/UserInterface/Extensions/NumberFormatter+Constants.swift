//
//  NumberFormatter+Constants.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-05.
//

import Foundation

public extension NumberFormatter {

  static let noDecimalPlaces: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 0
    formatter.numberStyle = .decimal
    return formatter
  }()

  static let oneDecimalPlaces: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 1
    formatter.numberStyle = .decimal
    return formatter
  }()

  static let twoDecimalPlaces: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 2
    formatter.numberStyle = .decimal
    return formatter
  }()
}
