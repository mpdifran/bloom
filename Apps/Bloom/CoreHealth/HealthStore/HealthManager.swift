//
//  HealthManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import SwiftUI
import SFSafeSymbols
@preconcurrency import HealthKit
import AppFoundations
import SwiftData
import BloomFoundation
import Combine

public struct HealthTargetDetails: Sendable {
  public let targetWeight: Double
  public let goal: String
  public let weightLossSpeed: WeightLossSpeed

  public init(
    targetWeight: Double,
    goal: String,
    weightLossSpeed: WeightLossSpeed
  ) {
    self.targetWeight = targetWeight
    self.goal = goal
    self.weightLossSpeed = weightLossSpeed
  }
}

/// This is Legacy. Health Goal is now a freeform String.
public enum HealthGoal: String, CaseIterable, Identifiable {
  public var id: Self { self}

  case none
  case gainWeight
  case maintainWeight
  case loseWeight
}

public extension HealthGoal {
  var isWeightRelated: Bool {
    switch self {
    case .gainWeight, .maintainWeight, .loseWeight:
      true
    default:
      false
    }
  }

  var supportsWeightChangeSpeed: Bool {
    switch self {
    case .gainWeight, .loseWeight:
      true
    default:
      false
    }
  }

  var name: String {
    switch self {
    case .none:
      "Monitor Health"
    case .gainWeight:
      "Gain Weight"
    case .maintainWeight:
      "Maintain Weight"
    case .loseWeight:
      "Lose Weight"
    }
  }

  var image: Image {
    switch self {
    case .loseWeight, .maintainWeight, .gainWeight:
      Image(.logWeightIcon)
    case .none:
      if #available(iOS 18.0, *), #available(watchOS 11.0, *) {
        Image(systemSymbol: .heartTextClipboardFill)
      } else {
        Image(systemSymbol: .heartTextSquareFill)
      }
    }
  }

  var color: Color {
    switch self {
    case .none:
        .mutedBlue
    case .gainWeight, .maintainWeight, .loseWeight:
        .mutedIndigo
    }
  }
}

public enum WeightLossSpeed: String, CaseIterable, Identifiable, Sendable {
  public var id: Self { self }

  case slow
  case moderate
  case fast

  public var name: String {
    rawValue.capitalized
  }

  public var mifflinStJeorAdjustment: Double {
    switch self {
    case .slow: 250
    case .moderate: 500
    case .fast: 1000
    }
  }

  @MainActor
  public var weightLossDescription: String {
    let quantity: HKQuantity
    switch self {
    case .slow:
      quantity = HKQuantity(unit: .pound(), doubleValue: 0.5)
    case .moderate:
      quantity = HKQuantity(unit: .pound(), doubleValue: 1)
    case .fast:
      quantity = HKQuantity(unit: .pound(), doubleValue: 2)
    }

    return "About \(quantity.displayString(for: .pound(), formatter: .oneDecimalPlace)) a week."
  }
}

@MainActor
public final class HealthManager: ObservableObject {
  public static let shared = HealthManager()

  @AppStorage(.HealthDefaults.name.key, store: .group) public var name: String = ""
  @AppStorage(.HealthDefaults.isFemale.key, store: .group) public var isFemale = true
  @AppStorage(.HealthDefaults.height.key, store: .group) public var heightCM: Double = 0

  @Published public var birthday = Date.now {
    didSet { healthDefaults.setBirthday(birthday) }
  }
  @Published public var healthGoal: String {
    didSet { healthDefaults.set(healthGoal: healthGoal) }
  }
  @Published public var weightLossSpeed: WeightLossSpeed = .moderate {
    didSet { healthDefaults.setWeightLossSpeed(weightLossSpeed) }
  }
  @Published public var userReportedActivityLevel: ActivityLevelSummary.ActivityLevel? {
    didSet { healthDefaults.setUserReportedActivityLevel(userReportedActivityLevel) }
  }
  
  @Published public var selectedWorkoutEquipment: Set<String> = [] {
    didSet { healthDefaults.setSelectedWorkoutEquipment(Array(selectedWorkoutEquipment)) }
  }

  public var healthTargetDetails: HealthTargetDetails {
    HealthTargetDetails(
      targetWeight: targetWeight,
      goal: healthGoal,
      weightLossSpeed: weightLossSpeed
    )
  }

  @AppStorage(.HealthDefaults.targetWeight.key, store: .group) public var targetWeight: Double = 0
  @AppStorage(.HealthDefaults.isPregnant.key, store: .group) public var isPregnant = false
  @AppStorage(.HealthDefaults.isBreastFeeding.key, store: .group) public var isBreastfeeding = false

  public let healthStore = HKHealthStore()
  let healthDefaults = HealthDefaults.shared

  private init() {
    self.birthday = healthDefaults.getBirthday()
    self.healthGoal = healthDefaults.getHealthGoal()
    self.weightLossSpeed = healthDefaults.getWeightLossSpeed()
    self.selectedWorkoutEquipment = Set(healthDefaults.getSelectedWorkoutEquipment())

    if let activityLevel = healthDefaults.getActivityLevel() {
      self.userReportedActivityLevel = activityLevel
    }

    Task {
      await checkHeightFromHealthKit()
    }
  }
}

// MARK: Age, Sex, and Height

public extension HealthManager {

  func checkHeightFromHealthKit() async {
    if heightCM < 1 {
      let quantity = await HealthStoreFetcher.shared.fetchLatestSample(for: .height)?.quantity
      heightCM = quantity?.doubleValue(for: .meterUnit(with: .centi)) ?? 0
    }
  }

  func age() -> Int {
    birthday.toAge()
  }

  func sex() -> HKBiologicalSex {
    isFemale ? .female : .male
  }

  func height() -> HKQuantity {
    HKQuantity(unit: .meterUnit(with: .centi), doubleValue: heightCM)
  }

  func sexName() -> String {
    switch sex() {
    case .notSet:
      "Not Set"
    case .female:
      "Female"
    case .male:
      "Male"
    case .other:
      "Other"
    @unknown default:
      "Unknown"
    }
  }

  func targetWeightQuantity() -> HKQuantity {
    HKQuantity(unit: .pound(), doubleValue: targetWeight)
  }
}
