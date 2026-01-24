//
//  HealthDefaults.swift
//  Bloom
//
//  Created by Zach Radford on 2025-02-26.
//

import Foundation
import HealthKit
internal import TelemetryDeck

public extension String {
  /// Namespace for Health User Default Keys
  enum HealthDefaults: String {
    case name = "HealthManager.name"
    case height = "HealthManager.height"
    case birthMonth = "HealthManager.birthMonth"
    case birthYear = "HealthManager.birthYear"
    case focus = "HealthManager.healthGoal"
    case sexKind = "HealthManager.sexKind"
    case weightLossSpeed = "HealthManager.weightLossSpeed"
    case userReportedActivityLevel = "HealthManager.userReportedActivityLevel"
    case targetWeight = "HealthManager.targetWeight"
    case isPregnant = "HealthManager.isPregnant"
    case isBreastFeeding = "HealthManager.isBreastfeeding"
    case selectedWorkoutEquipment = "HealthManager.selectedWorkoutEquipment"
    case smokingStatus = "HealthManager.smokingStatus"
    case smokingQuitDate = "HealthManager.smokingQuitDate"

    public var key: String { rawValue }
  }
}

public struct HealthDefaults: Sendable {
  public static let shared = HealthDefaults()

  nonisolated(unsafe) private static let store: UserDefaults = .group

  private init() { }

  public static func migrateFromLegacyKeys() {
    let store = UserDefaults.group
    let birthdayKey = "HealthManager.birthday"
    let isFemaleKey = "HealthManager.isFemale"

    // Only migrate if old keys exist
    guard store.value(forKey: birthdayKey) != nil || store.value(forKey: isFemaleKey) != nil else {
      return
    }

    // Migrate birthday to birthYear
    if let birthday = store.value(forKey: birthdayKey) as? Date {
      let birthYear = Calendar.current.component(.year, from: birthday)
      store.set(birthYear, forKey: "HealthManager.birthYear")
      store.removeObject(forKey: birthdayKey)
    }

    // Migrate isFemale to sexKind
    if let isFemale = store.value(forKey: isFemaleKey) as? Bool {
      let sexKindRawValue = isFemale ? HKBiologicalSex.female.rawValue : HKBiologicalSex.male.rawValue
      store.set(sexKindRawValue, forKey: "HealthManager.sexKind")
      store.removeObject(forKey: isFemaleKey)
    }
  }
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
public extension HealthDefaults {
  func set(focus: String) {
    setValue(focus, for: .focus)
  }

  func setSexKind(_ sexKind: HKBiologicalSex) {
    setValue(sexKind.rawValue, for: .sexKind)
  }

  func setWeightLossSpeed(_ weightLossSpeed: WeightLossSpeed) {
    setValue(weightLossSpeed.rawValue, for: .weightLossSpeed)
  }

  func setUserReportedActivityLevel(_ activityLevel: ActivityLevelSummary.ActivityLevel?) {
    setValue(activityLevel?.rawValue, for: .userReportedActivityLevel)
  }
  
  func setSelectedWorkoutEquipment(_ equipment: [String]) {
    setValue(equipment, for: .selectedWorkoutEquipment)
  }

  func setSmokingStatus(_ status: SmokingStatus) {
    setValue(status.rawValue, for: .smokingStatus)
  }

  func setSmokingQuitDate(_ date: Date?) {
    if let date {
      setValue(date.timeIntervalSince1970, for: .smokingQuitDate)
    } else {
      setValue(nil, for: .smokingQuitDate)
    }
  }
}

public extension HealthDefaults {
  func getBirthMonth() -> Int {
    getValue(for: .birthMonth) ?? 0
  }

  func getBirthYear() -> Int {
    getValue(for: .birthYear) ?? 0
  }

  func getSexKind() -> HKBiologicalSex {
    if let value: Int = getValue(for: .sexKind),
       let kind = HKBiologicalSex(rawValue: value) {
      return kind
    }
    return .notSet
  }

  func getFocus() -> String {
    let value: String? = getValue(for: .focus)

    if let value, let healthGoalEnum = HealthGoal(rawValue: value) {
      return healthGoalEnum.name
    }

    return value ?? ""
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
  
  func getSelectedWorkoutEquipment() -> [String] {
    getValue(for: .selectedWorkoutEquipment) ?? []
  }

  func getSmokingStatus() -> SmokingStatus {
    if let value: String = getValue(for: .smokingStatus),
       let status = SmokingStatus(rawValue: value) {
      return status
    }
    return .unknown
  }

  func getSmokingQuitDate() -> Date? {
    guard let timestamp: TimeInterval = getValue(for: .smokingQuitDate) else {
      return nil
    }
    return Date(timeIntervalSince1970: timestamp)
  }
}

public extension Date {
  func toAge() -> Int {
    Calendar.current.dateComponents([.year], from: self, to: .now).year ?? 0
  }
}
