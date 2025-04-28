//
//  SetGoalsArguments.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-27.
//

import Foundation
import BloomModel

struct SetGoalsArguments: Codable, Equatable, Sendable {
  public let newGoals: [SocketMessage.HealthMetricGoal]
}
