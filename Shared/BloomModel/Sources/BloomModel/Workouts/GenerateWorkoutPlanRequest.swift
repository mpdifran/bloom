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

  /// BCP-47 tag for the language the plan's names and coaching notes should be written in.
  /// Optional for backwards compatibility.
  public let locale: String?

  public init(
    equipment: [String],
    description: String,
    locale: String? = nil
  ) {
    self.equipment = equipment
    self.description = description
    self.locale = locale
  }
}
