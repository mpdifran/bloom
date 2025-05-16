//
//  SocketMessageLogPeriod+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-16.
//

import BloomModel
import HealthKit

extension SocketMessage.LogPeriod.FlowLevel {

  var hkFlow: HKCategoryValueMenstrualFlow {
    switch self {
    case .none: .none
    case .light: .light
    case .medium: .medium
    case .heavy: .heavy
    }
  }
}
