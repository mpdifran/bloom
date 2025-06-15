//
//  SocketMessage+Workouts.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-06-12.
//

import Foundation

public extension SocketMessage {
  struct WorkoutPlan: Codable, Hashable, Sendable {
    public let title: String
    public let summary: String
    public let requiredEquipment: [Equipment]
    public let sets: [WorkoutSet]
    public let type: `Type`

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
      self.type = .workoutPlan
    }

    public init(from decoder: any Decoder) throws {
      let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
      self.title = try container.decode(String.self, forKey: .title)
      self.summary = try container.decode(String.self, forKey: .summary)
      let equipmentStrings = try container.decodeIfPresent([String].self, forKey: .requiredEquipment) ?? []
      self.requiredEquipment = equipmentStrings.compactMap { SocketMessage.WorkoutPlan.Equipment(rawValue: $0) }
      self.sets = try container.decode([SocketMessage.WorkoutSet].self, forKey: .sets)
      self.type = try container.decode(`Type`.self, forKey: .type)
    }

    public enum `Type`: String, Codable, Hashable, Sendable {
      case workoutPlan
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

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      self.title = try container.decode(String.self, forKey: .title)
      self.focus = try container.decode(String.self, forKey: .focus)
      self.numberOfSets = (try? container.decodeIfPresent(Int.self, forKey: .numberOfSets)) ?? 1
      self.format = (try? container.decodeIfPresent(SocketMessage.WorkoutSet.Format.self, forKey: .format)) ?? .standard
      self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)

      // If we can't parse the Apple Workout Type, set a sensible default
      if let workoutType = (try? container.decode(SocketMessage.AppleWorkoutType.self, forKey: .appleWorkoutType)) {
        self.appleWorkoutType = workoutType
      } else {
        switch format {
        case .warmup:
          self.appleWorkoutType = .preparationAndRecovery
        case .cooldown:
          self.appleWorkoutType = .cooldown
        case .amrap, .emom, .tabata:
          self.appleWorkoutType = .highIntensityIntervalTraining
        case .standard:
          self.appleWorkoutType = .other
        }
      }

      self.restBetweenExercises = (try? container.decodeIfPresent(TimeInterval.self, forKey: .restBetweenExercises)) ?? 0
      self.exercises = try container.decode([SocketMessage.WorkoutExercise].self, forKey: .exercises)
    }
  }

  struct WorkoutExercise: Codable, Hashable, Sendable {
    public let title: String
    public let instructions: String
    public let numberOfReps: Int?
    public let distance: Double?
    public let distanceUnit: DistanceUnit?
    public let duration: TimeInterval

    public init(
      title: String,
      instructions: String,
      numberOfReps: Int?,
      distance: Double?,
      distanceUnit: DistanceUnit?,
      duration: TimeInterval
    ) {
      self.title = title
      self.instructions = instructions
      self.numberOfReps = numberOfReps
      self.distance = distance
      self.distanceUnit = distanceUnit
      self.duration = duration
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      self.title = try container.decode(String.self, forKey: .title)
      self.instructions = try container.decode(String.self, forKey: .instructions)
      let numberOfReps = (try? container.decodeIfPresent(Int.self, forKey: .numberOfReps)) ?? 1
      self.numberOfReps = numberOfReps
      self.distance = try? container.decodeIfPresent(Double.self, forKey: .distance)
      self.distanceUnit = try? container.decodeIfPresent(SocketMessage.WorkoutExercise.DistanceUnit.self, forKey: .distanceUnit)
      self.duration = (try? container.decode(TimeInterval.self, forKey: .duration)) ?? TimeInterval(numberOfReps * 10)
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
    case cooldown
  }
}

public extension SocketMessage.WorkoutExercise {
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
