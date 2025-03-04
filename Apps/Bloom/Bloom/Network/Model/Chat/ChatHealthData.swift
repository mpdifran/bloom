//
//  ChatHealthData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import Foundation

protocol SendableNetworkModel: Codable, Equatable, Sendable { }

// MARK: - ChatHealthData

struct ChatHealthData: SendableNetworkModel {
  let demographics: Demographics?
  let activityLevel: ActivityLevel?
  let bodyComposition: BodyComposition?
  let bowelMovements: BowelMovements?
  let exerciseEffectiveness: ExerciseEffectiveness?
  let heartHealth: HeartHealth?
  let menstrualHealth: MenstrualHealth?
  let sleep: Sleep?
  let stress: Stress?
}

extension ChatHealthData {
  var isEmpty: Bool {
    demographics == nil &&
    activityLevel == nil &&
    bodyComposition == nil &&
    bowelMovements == nil &&
    exerciseEffectiveness == nil &&
    heartHealth == nil &&
    menstrualHealth == nil &&
    sleep == nil &&
    stress == nil
  }
}

// MARK: - Primitives

extension ChatHealthData {
  struct Sample: SendableNetworkModel {
    let date: Date
    let quantity: Quantity
  }

  struct Quantity: SendableNetworkModel {
    let value: String
    let unit: String

    init(value: String, unit: String) {
      self.value = value
      self.unit = unit
    }

    init(value: Double, unit: String, numberFormatter: NumberFormatter) {
      self.value = numberFormatter.string(for: value) ?? ""
      self.unit = unit
    }
  }

  struct QuantityRange: SendableNetworkModel {
    let lower: Quantity
    let upper: Quantity
  }

  struct BowelMovementSample: SendableNetworkModel {
    let date: Date
    let bristolStoolType: Int
    let duration: String
  }

  struct HeartRateZones: SendableNetworkModel {
    let heartRateReserve: Quantity
    let restingHeartRate: Quantity
    let maxHeartRate: Quantity
    let zone1: QuantityRange
    let zone2: QuantityRange
    let zone3: QuantityRange
    let zone4: QuantityRange
    let zone5: QuantityRange
  }

  struct HeartRateZoneWorkoutSample: SendableNetworkModel {
    let date: Date
    let workout: String
    let workoutDuration: Quantity
    let zone1Duration: Quantity
    let zone2Duration: Quantity
    let zone3Duration: Quantity
    let zone4Duration: Quantity
    let zone5Duration: Quantity
  }

  struct MenstrualCycle: SendableNetworkModel {
    let startDate: Date
    let flowSamples: [MenstrualFlowLevelSample]
  }

  struct MenstrualFlowLevelSample: SendableNetworkModel {
    let date: Date
    let flowLevel: FlowLevel

    enum FlowLevel: String, SendableNetworkModel {
      case none
      case light
      case medium
      case heavy
    }
  }

  struct SleepDay: SendableNetworkModel {
    let startDate: Date
    let endDate: Date
    let deepSleep: Quantity?
    let coreSleep: Quantity?
    let remSleep: Quantity?
    let awakeSleep: Quantity?
    let averageHeartRate: Quantity?
    let averageRespiratoryRate: Quantity?
    let averageDecibelAWeightedEnvironmentalSoundPressureLevel: Quantity?
    let wristTemperature: Quantity?
  }

  struct BloodPressureSample: SendableNetworkModel {
    let date: Date
    let systolic: Quantity
    let diastolic: Quantity
  }
}

// MARK: - Demographics

extension ChatHealthData {
  struct Demographics: SendableNetworkModel {
    let age: Int?
    let sex: String?
    let height: Quantity?
    let healthGoal: String?
  }
}

// MARK: - Activity Level

extension ChatHealthData {
  struct ActivityLevel: SendableNetworkModel {
    let basalEnergyBurned: [Sample]
    let activeEnergyBurned: [Sample]
  }
}

// MARK: - Body Composition

extension ChatHealthData {
  struct BodyComposition: SendableNetworkModel {
    let bodyFatPercentage: [Sample]
    let bodyMass: [Sample]
  }
}

// MARK: - Bowel Movement

extension ChatHealthData {
  struct BowelMovements: SendableNetworkModel {
    let samples: [BowelMovementSample]
  }
}

// MARK: - Exercise Effectiveness

extension ChatHealthData {
  struct ExerciseEffectiveness: SendableNetworkModel {
    let heartRateZones: HeartRateZones
    let heartRateZoneWorkoutSamples: [HeartRateZoneWorkoutSample]
  }
}

// MARK: - Heart Health

extension ChatHealthData {
  struct HeartHealth: SendableNetworkModel {
    let vo2Max: [Sample]
    let restingHeartRate: [Sample]
    let heartRateRecoveryOneMinute: [Sample]
  }
}

// MARK: - Menstrual Health

extension ChatHealthData {
  struct MenstrualHealth: SendableNetworkModel {
    let cycles: [MenstrualCycle]
  }
}

// MARK: - Sleep

extension ChatHealthData {
  struct Sleep: SendableNetworkModel {
    let sleepDetails: [SleepDay]
  }
}

// MARK: - Stress

extension ChatHealthData {
  struct Stress: SendableNetworkModel {
    let heartRateVariability: [Sample]
    let bloodPressureSamples: [BloodPressureSample]
  }
}
