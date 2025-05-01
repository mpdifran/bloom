//
//  BodyFatPercentageGoalThresholds.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

public struct BodyFatPercentageGoalThresholds: Hashable, Sendable {
  public let maxEssentialFat: Double
  public let maxAthleteFat: Double
  public let maxFitFat: Double
  public let maxHealthyFat: Double
  public let maxHighFat: Double

  public init(
    maxEssentialFat: Double,
    maxAthleteFat: Double,
    maxFitFat: Double,
    maxHealthyFat: Double,
    maxHighFat: Double
  ) {
    self.maxEssentialFat = maxEssentialFat
    self.maxAthleteFat = maxAthleteFat
    self.maxFitFat = maxFitFat
    self.maxHealthyFat = maxHealthyFat
    self.maxHighFat = maxHighFat
  }
}
