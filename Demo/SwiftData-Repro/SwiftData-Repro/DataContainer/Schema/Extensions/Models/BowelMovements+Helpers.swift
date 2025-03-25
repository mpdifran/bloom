//
//  BowelMovements+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-17.
//

import Foundation

public extension BowelMovement {

  var duration: Duration {
    Duration(rawValue: rawDuration) ?? .between5And10Min
  }
}

public extension BowelMovement {
  enum Duration: Int, CaseIterable, Identifiable, Sendable {
    public var id: Self { self }

    case lessThan5Min = 0
    case between5And10Min = 1
    case moreThan10Min = 2

    public var name: String {
      switch self {
      case .lessThan5Min:
        "< 5 min"
      case .between5And10Min:
        "5 - 10 min"
      case .moreThan10Min:
        "> 10 min"
      }
    }

    public var scoreModifier: Double {
      switch self {
      case .lessThan5Min:
        0.9
      case .between5And10Min:
        1
      case .moreThan10Min:
        0.75
      }
    }
  }
}
