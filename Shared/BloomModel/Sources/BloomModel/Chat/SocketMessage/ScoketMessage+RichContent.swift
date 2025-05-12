//
//  ScoketMessage+RichContent.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-27.
//

import Foundation

public extension SocketMessage {

  struct DetectedFood: Codable, Equatable, Sendable {
    public let name: String
    public let meal: Meal
    public let foodItemServings: [EstimateFoodCaloriesResponse.Serving]

    public init(
      name: String,
      meal: Meal,
      foodItemServings: [EstimateFoodCaloriesResponse.Serving]
    ) {
      self.name = name
      self.meal = meal
      self.foodItemServings = foodItemServings
    }
  }
}

public extension SocketMessage.DetectedFood {

  enum Meal: String, Codable, Equatable, Sendable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
  }
}

public extension SocketMessage {

  struct HealthMetricGoal: Codable, Equatable, Sendable {
    public let metric: SuggestedGoal.Metric
    public let timePeriod: SuggestedGoal.TimePeriod
    public let value: Double
    public let unit: SuggestedGoal.Unit

    public init(
      metric: SuggestedGoal.Metric,
      timePeriod: SuggestedGoal.TimePeriod,
      value: Double,
      unit: SuggestedGoal.Unit
    ) {
      self.metric = metric
      self.timePeriod = timePeriod
      self.value = value
      self.unit = unit
    }
  }

  struct LogWaterConsumption: Codable, Equatable, Sendable {
    public let amount: Double
    public let unit: Unit

    public init(amount: Double, unit: Unit) {
      self.amount = amount
      self.unit = unit
    }

    public enum Unit: String, Codable, Equatable, Sendable, CaseIterable {
      case mL
      case ozUS = "fl_oz_us"
      case ozUK = "fl_oz_imp"
    }
  }

  struct LogBowelMovement: Codable, Equatable, Sendable {
    public let bristolStoolType: Int
    public let duration: Duration

    public init(bristolStoolType: Int, duration: Duration) {
      self.bristolStoolType = bristolStoolType
      self.duration = duration
    }

    public enum Duration: String, Codable, Equatable, Sendable, CaseIterable {
      case lessThan5Min
      case between5And10Min
      case moreThan10Min
    }
  }

  struct LogWeight: Codable, Equatable, Sendable {
    public let value: Double
    public let unit: Unit

    public init(value: Double, unit: Unit) {
      self.value = value
      self.unit = unit
    }

    public enum Unit: String, Codable, Equatable, Sendable, CaseIterable {
      case lb
      case kg
    }
  }

  struct LogBloodPressure: Codable, Equatable, Sendable {
    public let systolic: Int
    public let diastolic: Int

    public init(systolic: Int, diastolic: Int) {
      self.systolic = systolic
      self.diastolic = diastolic
    }
  }

  struct WorkoutPlan: Codable, Hashable, Sendable {
    public let title: String
    public let summary: String
    public let requiredEquipment: [Equipment]
    public let sets: [WorkoutSet]

    public init(
      title: String,
      summary: String,
      requiredEquipment: [Equipment],
      sets: [WorkoutSet]
    ) {
      self.title = title
      self.summary = summary
      self.requiredEquipment = requiredEquipment
      self.sets = sets
    }
  }

  struct WorkoutSet: Codable, Hashable, Sendable {
    public let title: String
    public let focus: String
    public let numberOfSets: Int
    public let format: Format
    public let duration: TimeInterval?
    public let appleWorkoutType: AppleWorkoutType
    public let restBetweenExercises: TimeInterval
    public let exercises: [WorkoutExercise]

    public init(
      title: String,
      focus: String,
      numberOfSets: Int,
      format: Format,
      duration: TimeInterval?,
      appleWorkoutType: AppleWorkoutType,
      restBetweenExercises: TimeInterval,
      exercises: [WorkoutExercise]
    ) {
      self.title = title
      self.focus = focus
      self.numberOfSets = numberOfSets
      self.format = format
      self.duration = duration
      self.appleWorkoutType = appleWorkoutType
      self.restBetweenExercises = restBetweenExercises
      self.exercises = exercises
    }
  }

  struct WorkoutExercise: Codable, Hashable, Sendable {
    public let title: String
    public let description: String
    public let numberOfReps: Int?
    public let kind: Kind
    public let distance: Double?
    public let distanceUnit: DistanceUnit?
    public let duration: TimeInterval

    public init(
      title: String,
      description: String,
      numberOfReps: Int?,
      kind: Kind,
      distance: Double?,
      distanceUnit: DistanceUnit?,
      duration: TimeInterval
    ) {
      self.title = title
      self.description = description
      self.numberOfReps = numberOfReps
      self.kind = kind
      self.distance = distance
      self.distanceUnit = distanceUnit
      self.duration = duration
    }
  }
}

public extension SocketMessage.WorkoutPlan {
  enum Equipment: String, Codable, Hashable, Sendable, CaseIterable {
    case dumbbells
    case barbell
    case kettlebell
    case batBell
    case chinUpBar
    case treadmill
    case stationaryBike
    case bike
    case elliptical
    case rowingMachine
    case skiMachine
    case yogaMat
    case resistanceBand
    case weightedVest

    public var name: String {
      switch self {
      case .dumbbells: "Dumbbells"
      case .barbell: "Barbell"
      case .kettlebell: "Kettlebell"
      case .batBell: "Batbell"
      case .chinUpBar: "Chin-up Bar"
      case .treadmill: "Treadmill"
      case .stationaryBike: "Stationary Bike"
      case .bike: "Bike"
      case .elliptical: "Elliptical"
      case .rowingMachine: "Rowing Machine"
      case .skiMachine: "Ski Machine"
      case .yogaMat: "Yoga Mat"
      case .resistanceBand: "Resistance Band"
      case .weightedVest: "Weighted Vest"
      }
    }
  }
}

public extension SocketMessage.WorkoutSet {
  enum Format: String, Codable, Hashable, Sendable, CaseIterable {
    case warmup
    case standard
    case amrap
    case emom
    case tabata
    case coolDown
  }
}

public extension SocketMessage.WorkoutExercise {
  enum Kind: String, Codable, Hashable, Sendable, CaseIterable {
    case exercise
    case stretch
  }

  enum DistanceUnit: String, Codable, Hashable, Sendable, CaseIterable {
    case meter
    case kilometer
    case mile
    case yard
    case foot
  }
}

public extension SocketMessage {
  enum AppleWorkoutType: String, Codable, Hashable, Sendable, CaseIterable {
    case americanFootball
    case archery
    case australianFootball
    case badminton
    case baseball
    case basketball
    case bowling
    case boxing
    case climbing
    case cricket
    case crossTraining
    case curling
    case cycling
    case elliptical
    case equestrianSports
    case fencing
    case fishing
    case functionalStrengthTraining
    case golf
    case gymnastics
    case handball
    case hiking
    case hockey
    case hunting
    case lacrosse
    case martialArts
    case mindAndBody
    case paddleSports
    case play
    case preparationAndRecovery
    case racquetball
    case rowing
    case rugby
    case running
    case sailing
    case skatingSports
    case snowSports
    case soccer
    case softball
    case squash
    case stairClimbing
    case surfingSports
    case swimming
    case tableTennis
    case tennis
    case trackAndField
    case traditionalStrengthTraining
    case volleyball
    case walking
    case waterFitness
    case waterPolo
    case waterSports
    case wrestling
    case yoga
    case barre
    case coreTraining
    case crossCountrySkiing
    case downhillSkiing
    case flexibility
    case highIntensityIntervalTraining
    case jumpRope
    case kickboxing
    case pilates
    case snowboarding
    case stairs
    case stepTraining
    case wheelchairWalkPace
    case wheelchairRunPace
    case taiChi
    case mixedCardio
    case handCycling
    case discSports
    case fitnessGaming
    case cardioDance
    case socialDance
    case pickleball
    case cooldown
    case swimBikeRun
    case transition
    case underwaterDiving
    case other
  }
}
