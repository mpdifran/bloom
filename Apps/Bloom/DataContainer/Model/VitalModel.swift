//
//  VitalModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI

public extension VitalModel {
  enum Kind: String, Hashable, Codable, CaseIterable, Sendable {
    case cardioFitness
    case sleepQuality
    case activityLevel
    case heartHealth
    case bodyComposition
    case stressLevels
    case nutrition
    case exerciseEffectiveness
    case cycleTracking
    case bowelMovements

    public var name: String {
      switch self {
        // TODO: Get rid of the cardioFitness case
      case .cardioFitness:
        "Cardio Fitness"
      case .sleepQuality:
        "Sleep Quality"
      case .activityLevel:
        "Activity Level"
      case .heartHealth:
        "Heart Health"
      case .bodyComposition:
        "Body Composition"
      case .stressLevels:
        "Stress Levels"
      case .nutrition:
        "Nutrition"
      case .exerciseEffectiveness:
        "Exercise Effectiveness"
      case .cycleTracking:
        "Cycle Tracking"
      case .bowelMovements:
        "Bowel Movements"
      }
    }

    public var systemImage: String {
      switch self {
      case .sleepQuality:
        "moon.zzz.fill"
      case .activityLevel:
        "figure.tennis"
      case .heartHealth, .cardioFitness:
        "heart.fill"
      case .bodyComposition:
        "gauge.with.needle"
      case .stressLevels:
        "bolt.fill"
      case .nutrition:
        "fork.knife"
      case .exerciseEffectiveness:
        "figure.mixed.cardio"
      case .cycleTracking:
        "circle.dotted.and.circle"
      case .bowelMovements:
        "toilet.fill"
      }
    }

    public var supportsSuggestedGoals: Bool {
      switch self {
      case .activityLevel,
          .heartHealth,
          .stressLevels,
          .exerciseEffectiveness,
          .bowelMovements,
          .nutrition:
        return true
      case .sleepQuality, // No goals yet!
          .bodyComposition,
          .cycleTracking,
          .cardioFitness:
        return false
      }
    }
  }

  enum Level: Int, Hashable, Sendable {
    case low
    case medium
    case high
    case optimal
  }

  struct BarLevel: Hashable, Sendable {
    public let level: Level
    public let proportion: Double

    public init(
      level: Level,
      proportion: Double
    ) {
      self.level = level
      self.proportion = proportion
    }
  }
}

extension VitalModel.BarLevel: Comparable {
  public static func < (lhs: VitalModel.BarLevel, rhs: VitalModel.BarLevel) -> Bool {
    if lhs.level == rhs.level {
      return lhs.proportion < rhs.proportion
    }
    return lhs.level.rawValue < rhs.level.rawValue
  }
}

public struct VitalModel: Identifiable, Hashable, Sendable {
  public let id: Kind
  public let subtitle: String
  public let status: String
  public let color: Color
  public let barLevel: BarLevel?
  public let hasNoData: Bool

  public init(
    id: Kind,
    subtitle: String?,
    status: String?,
    color: Color?,
    barLevel: BarLevel?,
    hasNoData: Bool
  ) {
    self.id = id
    self.subtitle = subtitle ?? "No Data"
    self.status = status ?? "Unknown"
    self.color = color ?? .gray
    self.barLevel = barLevel
    self.hasNoData = hasNoData
  }

  public init(id: Kind) {
    self.init(
      id: id,
      subtitle: nil,
      status: nil,
      color: nil,
      barLevel: nil,
      hasNoData: true
    )
  }
}
