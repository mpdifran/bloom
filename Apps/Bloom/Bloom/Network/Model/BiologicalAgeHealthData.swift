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
    let nutrition: NutritionMetrics?
    let bodyComposition: BodyMetrics?
    let recovery: RecoveryIndicators?
  }
}

extension BiologicalAgeHealthData {
  
  struct MetricValue: Codable, Sendable {
    let value: String
    let trend: Trend?
    
    enum Trend: String, Codable, Sendable {
      case increasing
      case stable
      case decreasing
    }
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
      let trend: MetricValue.Trend?
    }
    
    struct HRVMetric: Codable, Sendable {
      let average: String
      let trend: MetricValue.Trend?
    }
  }
  
  struct SleepMetrics: Codable, Sendable {
    let averageSleepDuration: MetricValue?
    let averageSleepEfficiency: MetricValue?
    let averageDeepSleep: SleepStageMetric?
    let averageRemSleep: SleepStageMetric?
    let averageWakeMinutes: MetricValue?
    
    struct SleepStageMetric: Codable, Sendable {
      let averageMinutes: String
      let averagePercentage: String
      let trend: MetricValue.Trend?
    }
  }
  
  struct ActivityMetrics: Codable, Sendable {
    let averageDailySteps: MetricValue?
    let averageActiveEnergy: MetricValue?
    let totalExerciseMinutes: MetricValue?
    let totalWorkoutCount: Int?
    let averageWalkingSpeed: MetricValue?
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
    let morningRestingHRTrend: MetricValue.Trend?
    let hrvTrend: MetricValue.Trend?
    let daysSinceLastWorkout: Int?
  }
}