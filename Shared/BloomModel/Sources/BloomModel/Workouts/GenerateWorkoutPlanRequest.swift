//
//  GenerateWorkoutPlanRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2026-02-11.
//

import Foundation

public struct GenerateWorkoutPlanRequest: Codable, Equatable, Sendable {
  public let equipment: [String]
  public let description: String

  public init(
    equipment: [String],
    description: String
  ) {
    self.equipment = equipment
    self.description = description
  }
}
