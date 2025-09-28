//
//  BiologicalAgeHealthData.swift
//  Bloom
//
//  Created by Assistant on 2025-09-15.
//

import Foundation
import HealthKit

struct BiologicalAgeHealthData: Codable, Sendable {
  let sevenDayAverage: SevenDayAverage?
  let biologicalSex: String?
  
  enum CodingKeys: String, CodingKey {
    case sevenDayAverage = "last7Days"
    case biologicalSex
  }
  
  struct SevenDayAverage: Codable, Sendable {
    let cardiovascular: CardiovascularHealth?
    let sleep: SleepMetrics?
    let activity: ActivityMetrics?
    let mobility: MobilityMetrics?
    let nutrition: NutritionMetrics?
    let bodyComposition: BodyMetrics?
    let recovery: RecoveryIndicators?
  }
}

extension BiologicalAgeHealthData {
  
  struct MetricValue: Codable, Sendable {
    let value: String
  }
  
  struct CardiovascularHealth: Codable, Sendable {
    let averageRestingHeartRate: HeartRateMetric?
    let averageHeartRateVariability: HRVMetric?
    let averageVO2Max: MetricValue?
    let averageHeartRateRecovery: MetricValue?
    
    struct HeartRateMetric: Codable, Sendable {
      let average: String
      let min: String
      let max: String
    }
    
    struct HRVMetric: Codable, Sendable {
      let average: String
    }
  }
  
  struct SleepMetrics: Codable, Sendable {
    let averageSleepDuration: MetricValue?
    let averageSleepEfficiency: MetricValue?
    let averageDeepSleep: SleepStageMetric?
    let averageRemSleep: SleepStageMetric?
    let averageWakeMinutes: MetricValue?
    let averageBedtime: MetricValue?
    let averageWakeupTime: MetricValue?

    struct SleepStageMetric: Codable, Sendable {
      let averageMinutes: String
      let averagePercentage: String
    }
  }
  
  struct ActivityMetrics: Codable, Sendable {
    let averageActiveEnergy: MetricValue?
    let totalExerciseMinutes: MetricValue?
    let totalWorkoutCount: Int?
  }
  
  struct NutritionMetrics: Codable, Sendable {
    let averageCalories: MetricValue?
    let averageProtein: MetricValue?
    let averageCarbohydrates: MetricValue?
    let averageTotalFat: MetricValue?
    let averageFiber: MetricValue?
    let averageSugar: MetricValue?
    let averageSaturatedFat: MetricValue?
    let averageDietQuality: DietQuality?
    
    struct DietQuality: Codable, Sendable {
      let processedFoodScore: ProcessedFoodLevel
      let vegetableServings: Double?
      
      enum ProcessedFoodLevel: String, Codable, Sendable {
        case low
        case medium
        case high
      }
    }
  }
  
  struct BodyMetrics: Codable, Sendable {
    let averageWeight: MetricValue?
    let averageBMI: MetricValue?
    let averageBodyFatPercentage: MetricValue?
  }
  
  struct RecoveryIndicators: Codable, Sendable {
    let daysSinceLastWorkout: Int?
  }

  struct MobilityMetrics: Codable, Sendable {
    let walkingSteadiness: MetricValue?
    let walkingSpeed: MetricValue?
    let doubleSupportPercentage: MetricValue?
    let walkingAsymmetryPercentage: MetricValue?
    let sixMinuteWalkDistance: MetricValue?
    let stairAscentSpeed: MetricValue?
    let stairDescentSpeed: MetricValue?
  }
}