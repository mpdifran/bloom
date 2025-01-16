//
//  HealthManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import SwiftUI
import HealthKit
import AppFoundations
import SwiftData
import BloomFoundation

struct HealthTargetDetails {
  let targetWeight: Double
  let goal: HealthGoal
  let weightLossSpeed: WeightLossSpeed
}

enum HealthGoal: String, CaseIterable, Identifiable {
  var id: Self { self}

  case none
  case gainWeight
  case maintainWeight
  case loseWeight
}

extension HealthGoal {
  var isWeightRelated: Bool {
    switch self {
    case .gainWeight, .maintainWeight, .loseWeight:
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
      Image(systemName: "heart.text.clipboard.fill")
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

enum WeightLossSpeed: String, CaseIterable, Identifiable {
  var id: Self { self }

  case slow
  case moderate
  case fast

  var name: String {
    rawValue.capitalized
  }

  var mifflinStJeorAdjustment: Double {
    switch self {
    case .slow: 250
    case .moderate: 500
    case .fast: 1000
    }
  }

  @MainActor
  var weightLossDescription: String {
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
final class HealthManager: ObservableObject {
  static let shared = HealthManager()

  @AppStorage("HealthManager.name", store: .group) var name: String = ""
  @AppStorage("HealthManager.isFemale", store: .group) var isFemale = false
  @AppStorage("HealthManager.height", store: .group) var heightCM: Double = 0

  @Published var birthday = Date.now {
    didSet { UserDefaults.group.set(birthday, forKey: "HealthManager.birthday") }
  }
  @Published var healthGoal: HealthGoal = .none {
    didSet { UserDefaults.group.set(healthGoal.rawValue, forKey: "HealthManager.healthGoal") }
  }
  @Published var weightLossSpeed: WeightLossSpeed = .moderate {
    didSet { UserDefaults.group.set(weightLossSpeed.rawValue, forKey: "HealthManager.weightLossSpeed") }
  }
  @Published var userReportedActivityLevel: ActivityLevelSummary.ActivityLevel? {
    didSet { UserDefaults.group.set(userReportedActivityLevel?.rawValue, forKey: "HealthManager.userReportedActivityLevel") }
  }

  var healthTargetDetails: HealthTargetDetails {
    HealthTargetDetails(
      targetWeight: targetWeight,
      goal: healthGoal,
      weightLossSpeed: weightLossSpeed
    )
  }

  @AppStorage("HealthManager.targetWeight", store: .group) var targetWeight: Double = 0
  @AppStorage("HealthManager.isPregnant", store: .group) var isPregnant = false
  @AppStorage("HealthManager.isBreastfeeding", store: .group) var isBreastfeeding = false

  let healthStore = HKHealthStore()

  private init() {
    if let birthday = UserDefaults.group.object(forKey: "HealthManager.birthday") as? Date {
      self.birthday = birthday
    }
    if let healthGoalRaw = UserDefaults.group.string(forKey: "HealthManager.healthGoal") {
      self.healthGoal = HealthGoal(rawValue: healthGoalRaw) ?? .none
    }
    if let weightLossSpeedRaw = UserDefaults.group.string(forKey: "HealthManager.weightLossSpeed") {
      self.weightLossSpeed = WeightLossSpeed(rawValue: weightLossSpeedRaw) ?? .moderate
    }
    if let activityLevelRaw = UserDefaults.group.string(forKey: "HealthManager.userReportedActivityLevel") {
      self.userReportedActivityLevel = ActivityLevelSummary.ActivityLevel(rawValue: activityLevelRaw)
    }

    Task {
      await checkHeightFromHealthKit()
    }
  }
}

// MARK: Age, Sex, and Height

extension HealthManager {

  func checkHeightFromHealthKit() async {
    if heightCM < 1 {
      let quantity = await HealthStoreFetcher.shared.fetchLatestSample(for: .height)?.quantity
      heightCM = quantity?.doubleValue(for: .meterUnit(with: .centi)) ?? 0
    }
  }

  func age() -> Int {
    if let age = healthStore.age() {
      return age
    }
    return Calendar.current.dateComponents([.year], from: birthday, to: .now).year ?? 0
  }

  func sex() -> HKBiologicalSex {
    if let sex = healthStore.sex() {
      return sex
    }
    return isFemale ? .female : .male
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

  func healthGaolAssociatedValueString() -> String {
    switch healthGoal {
    case .loseWeight, .gainWeight, .maintainWeight:
      targetWeightQuantity().displayString(for: .pound(), formatter: .oneDecimalPlace)
    case .none:
      ""
    }
  }

  func healthGoalDisplayString() -> String {
    switch (healthGoal, weightLossSpeed) {
    case (.loseWeight, .slow):
      "Lose Weight Slowly"
    case (.loseWeight, .moderate):
      "Lose Weight Moderately"
    case (.loseWeight, .fast):
      "Lose Weight Fast"
    case (.gainWeight, .slow):
      "Gain Weight Slowly"
    case (.gainWeight, .moderate):
      "Gain Weight Moderately"
    case (.gainWeight, .fast):
      "Gain Weight Fast"
    case (.maintainWeight, _):
      "Maintain Weight"
    case (.none, _):
      "Monitor Health"
    }
  }
}

// MARK: Health Goals

extension HealthManager {

  func hasMetWeightGoal(for bodyMass: HKQuantity) -> Bool {
    let weight = bodyMass.doubleValue(for: .pound())

    switch healthGoal {
    case .loseWeight:
      return weight < targetWeight
    case .gainWeight:
      return weight > targetWeight
    case .maintainWeight:
      return false
    case .none:
      return false
    }
  }
}
