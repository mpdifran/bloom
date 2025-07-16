//
//  SocketMessage+Conversions.swift
//  Bloom
//
//  Created by Assistant on 2025-05-24.
//

import Foundation
import BloomModel
import DataContainer

extension SocketMessage.LogBowelMovement.Duration {
  var asBowelMovementDuration: BowelMovement.Duration {
    switch self {
    case .lessThan5Min:
      return .lessThan5Min
    case .between5And10Min:
      return .between5And10Min
    case .moreThan10Min:
      return .moreThan10Min
    }
  }
}
