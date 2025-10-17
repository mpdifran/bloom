//
//  BiologicalAgeHealthData.swift
//  Bloom
//
//  Created by Assistant on 2025-09-15.
//

import Foundation
import HealthKit

public struct BiologicalAgeHealthData: Codable, Sendable {
  public let sevenDayAverage: SevenDayAverage?
  public let biologicalSex: String?

  enum CodingKeys: String, CodingKey {
    case sevenDayAverage = "last7Days"
    case biologicalSex
  }

  public init(sevenDayAverage: SevenDayAverage?, biologicalSex: String?) {
    self.sevenDayAverage = sevenDayAverage
    self.biologicalSex = biologicalSex
  }

  public struct SevenDayAverage: Codable, Sendable {
    public let cardiovascular: CardiovascularHealth?
    public let sleep: SleepMetrics?
    public let activity: ActivityMetrics?
    public let mobility: MobilityMetrics?
    public let nutrition: NutritionMetrics?
    public let bodyComposition: BodyMetrics?
    public let recovery: RecoveryIndicators?

    public init(cardiovascular: CardiovascularHealth?, sleep: SleepMetrics?, activity: ActivityMetrics?, mobility: MobilityMetrics?, nutrition: NutritionMetrics?, bodyComposition: BodyMetrics?, recovery: RecoveryIndicators?) {
      self.cardiovascular = cardiovascular
      self.sleep = sleep
      self.activity = activity
      self.mobility = mobility
      self.nutrition = nutrition
      self.bodyComposition = bodyComposition
      self.recovery = recovery
    }
  }
}

public extension BiologicalAgeHealthData {

  struct MetricValue: Codable, Sendable {
    public let value: String

    public init(value: String) {
      self.value = value
    }
  }

  struct CardiovascularHealth: Codable, Sendable {
    public let averageRestingHeartRate: HeartRateMetric?
    public let averageHeartRateVariability: HRVMetric?
    public let averageVO2Max: MetricValue?
    public let averageHeartRateRecovery: MetricValue?

    public struct HeartRateMetric: Codable, Sendable {
      public let average: String
      public let min: String
      public let max: String

      public init(average: String, min: String, max: String) {
        self.average = average
        self.min = min
        self.max = max
      }
    }

    public struct HRVMetric: Codable, Sendable {
      public let average: String

      public init(average: String) {
        self.average = average
      }
    }

    public init(averageRestingHeartRate: HeartRateMetric?, averageHeartRateVariability: HRVMetric?, averageVO2Max: MetricValue?, averageHeartRateRecovery: MetricValue?) {
      self.averageRestingHeartRate = averageRestingHeartRate
      self.averageHeartRateVariability = averageHeartRateVariability
      self.averageVO2Max = averageVO2Max
      self.averageHeartRateRecovery = averageHeartRateRecovery
    }
  }
  
  struct SleepMetrics: Codable, Sendable {
    public let averageSleepDuration: MetricValue?
    public let averageSleepEfficiency: MetricValue?
    public let averageDeepSleep: SleepStageMetric?
    public let averageRemSleep: SleepStageMetric?
    public let averageWakeMinutes: MetricValue?
    public let averageBedtime: MetricValue?
    public let averageWakeupTime: MetricValue?

    public struct SleepStageMetric: Codable, Sendable {
      public let averageMinutes: String
      public let averagePercentage: String

      public init(averageMinutes: String, averagePercentage: String) {
        self.averageMinutes = averageMinutes
        self.averagePercentage = averagePercentage
      }
    }

    public init(averageSleepDuration: MetricValue?, averageSleepEfficiency: MetricValue?, averageDeepSleep: SleepStageMetric?, averageRemSleep: SleepStageMetric?, averageWakeMinutes: MetricValue?, averageBedtime: MetricValue?, averageWakeupTime: MetricValue?) {
      self.averageSleepDuration = averageSleepDuration
      self.averageSleepEfficiency = averageSleepEfficiency
      self.averageDeepSleep = averageDeepSleep
      self.averageRemSleep = averageRemSleep
      self.averageWakeMinutes = averageWakeMinutes
      self.averageBedtime = averageBedtime
      self.averageWakeupTime = averageWakeupTime
    }
  }
  
  struct ActivityMetrics: Codable, Sendable {
    public let averageActiveEnergy: MetricValue?
    public let totalExerciseMinutes: MetricValue?
    public let totalWorkoutCount: Int?

    public init(averageActiveEnergy: MetricValue?, totalExerciseMinutes: MetricValue?, totalWorkoutCount: Int?) {
      self.averageActiveEnergy = averageActiveEnergy
      self.totalExerciseMinutes = totalExerciseMinutes
      self.totalWorkoutCount = totalWorkoutCount
    }
  }
  
  struct NutritionMetrics: Codable, Sendable {
    public let averageCalories: MetricValue?
    public let averageProtein: MetricValue?
    public let averageCarbohydrates: MetricValue?
    public let averageTotalFat: MetricValue?
    public let averageFiber: MetricValue?
    public let averageSugar: MetricValue?
    public let averageSaturatedFat: MetricValue?
    public let averageDietQuality: DietQuality?

    public struct DietQuality: Codable, Sendable {
      public let processedFoodScore: ProcessedFoodLevel
      public let vegetableServings: Double?

      public enum ProcessedFoodLevel: String, Codable, Sendable {
        case low
        case medium
        case high
      }

      public init(processedFoodScore: ProcessedFoodLevel, vegetableServings: Double?) {
        self.processedFoodScore = processedFoodScore
        self.vegetableServings = vegetableServings
      }
    }

    public init(averageCalories: MetricValue?, averageProtein: MetricValue?, averageCarbohydrates: MetricValue?, averageTotalFat: MetricValue?, averageFiber: MetricValue?, averageSugar: MetricValue?, averageSaturatedFat: MetricValue?, averageDietQuality: DietQuality?) {
      self.averageCalories = averageCalories
      self.averageProtein = averageProtein
      self.averageCarbohydrates = averageCarbohydrates
      self.averageTotalFat = averageTotalFat
      self.averageFiber = averageFiber
      self.averageSugar = averageSugar
      self.averageSaturatedFat = averageSaturatedFat
      self.averageDietQuality = averageDietQuality
    }
  }
  
  struct BodyMetrics: Codable, Sendable {
    public let averageWeight: MetricValue?
    public let averageBMI: MetricValue?
    public let averageBodyFatPercentage: MetricValue?

    public init(averageWeight: MetricValue?, averageBMI: MetricValue?, averageBodyFatPercentage: MetricValue?) {
      self.averageWeight = averageWeight
      self.averageBMI = averageBMI
      self.averageBodyFatPercentage = averageBodyFatPercentage
    }
  }

  struct RecoveryIndicators: Codable, Sendable {
    public let daysSinceLastWorkout: Int?

    public init(daysSinceLastWorkout: Int?) {
      self.daysSinceLastWorkout = daysSinceLastWorkout
    }
  }

  struct MobilityMetrics: Codable, Sendable {
    public let walkingSteadiness: MetricValue?
    public let walkingSpeed: MetricValue?
    public let doubleSupportPercentage: MetricValue?
    public let walkingAsymmetryPercentage: MetricValue?
    public let sixMinuteWalkDistance: MetricValue?
    public let stairAscentSpeed: MetricValue?
    public let stairDescentSpeed: MetricValue?

    public init(walkingSteadiness: MetricValue?, walkingSpeed: MetricValue?, doubleSupportPercentage: MetricValue?, walkingAsymmetryPercentage: MetricValue?, sixMinuteWalkDistance: MetricValue?, stairAscentSpeed: MetricValue?, stairDescentSpeed: MetricValue?) {
      self.walkingSteadiness = walkingSteadiness
      self.walkingSpeed = walkingSpeed
      self.doubleSupportPercentage = doubleSupportPercentage
      self.walkingAsymmetryPercentage = walkingAsymmetryPercentage
      self.sixMinuteWalkDistance = sixMinuteWalkDistance
      self.stairAscentSpeed = stairAscentSpeed
      self.stairDescentSpeed = stairDescentSpeed
    }
  }
}