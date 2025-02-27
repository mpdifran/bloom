//
//  HealthDefaults.swift
//  Bloom
//
//  Created by Zach Radford on 2025-02-26.
//

import Foundation

struct HealthDefaults {
  enum Key: String {
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

    var value: String { rawValue }
  }

  nonisolated(unsafe) private static let store: UserDefaults = .group
}

private extension HealthDefaults {
  func getValue<T>(for key: Key) -> T? {
    HealthDefaults.store.value(forKey: key.rawValue) as? T
  }

  @MainActor
  func setValue<T>(_ value: T, for key: Key) {
    HealthDefaults.store.set(value, forKey: key.rawValue)
  }
}

@MainActor
extension HealthDefaults {
  func setBirthday(_ birthday: Date) {
    setValue(birthday, for: .birthday)
  }

  func setHealthGoal(_ healthGoal: HealthGoal) {
    setValue(healthGoal.rawValue, for: .healthGoal)
  }

  func setWeightLossSpeed(_ weightLossSpeed: WeightLossSpeed) {
    setValue(weightLossSpeed.rawValue, for: .weightLossSpeed)
  }

  func setUserReportedActivityLevel(_ activityLevel: ActivityLevelSummary.ActivityLevel?) {
    setValue(activityLevel?.rawValue, for: .userReportedActivityLevel)
  }
}

extension HealthDefaults {
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
