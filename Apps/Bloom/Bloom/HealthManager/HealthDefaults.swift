//
//  HealthDefaults.swift
//  Bloom
//
//  Created by Zach Radford on 2025-02-26.
//

import Foundation
import TelemetryDeck

extension String {
  /// Namespace for Health User Default Keys
  enum HealthDefaults: String {
    case name = "HealthManager.name"
    case isFemale = "HealthManager.isFemale"
    case height = "HealthManager.height"
    case birthday = "HealthManager.birthday"
    case healthGoal = "HealthManager.healthGoal"
    case weightLossSpeed = "HealthManager.weightLossSpeed"
    case userReportedActivityLevel = "HealthManager.userReportedActivityLevel"
    case targetWeight = "HealthManager.targetWeight"
    case isPregnant = "HealthManager.isPregnant"
    case isBreastFeeding = "HealthManager.isBreastfeeding"

    var key: String { rawValue }
  }
}

struct HealthDefaults {
  static let shared = HealthDefaults()

  nonisolated(unsafe) private static let store: UserDefaults = .group
}

private extension HealthDefaults {
  func getValue<T>(for key: String.HealthDefaults) -> T? {
    HealthDefaults.store.value(forKey: key.key) as? T
  }

  @MainActor
  func setValue(_ value: Any?, for key: String.HealthDefaults) {
    HealthDefaults.store.set(value, forKey: key.key)
  }
}

@MainActor
extension HealthDefaults {
  func setBirthday(_ birthday: Date) {
    setValue(birthday, for: .birthday)
  }

  func setHealthGoal(_ healthGoal: HealthGoal) {
    setValue(healthGoal.rawValue, for: .healthGoal)
    TelemetryDeck.signal("Update Health Goal", parameters: ["healthGoal": healthGoal.name])
  }

  func setWeightLossSpeed(_ weightLossSpeed: WeightLossSpeed) {
    setValue(weightLossSpeed.rawValue, for: .weightLossSpeed)
  }

  func setUserReportedActivityLevel(_ activityLevel: ActivityLevelSummary.ActivityLevel?) {
    setValue(activityLevel?.rawValue, for: .userReportedActivityLevel)
  }
}

extension HealthDefaults {
  func getIsFemale() -> Bool {
    getValue(for: .isFemale) ?? true
  }

  func getBirthday() -> Date {
    getValue(for: .birthday) ?? Date.now
  }

  func getHealthGoal() -> HealthGoal {
    if
      let value: String = getValue(for: .healthGoal),
      let goal = HealthGoal(rawValue: value) {
      goal
    } else {
      .none
    }
  }

  func getWeightLossSpeed() -> WeightLossSpeed {
    if
      let value: String = getValue(for: .weightLossSpeed),
      let weightLossSpeed = WeightLossSpeed(rawValue: value) {
      weightLossSpeed
    } else {
      .moderate
    }
  }

  func getActivityLevel() -> ActivityLevelSummary.ActivityLevel? {
    if
      let value: String = getValue(for: .userReportedActivityLevel),
      let activityLevel = ActivityLevelSummary.ActivityLevel(rawValue: value) {
      activityLevel
    } else {
      nil
    }
  }
}

extension Date {
  func toAge() -> Int {
    Calendar.current.dateComponents([.year], from: self, to: .now).year ?? 0
  }
}
