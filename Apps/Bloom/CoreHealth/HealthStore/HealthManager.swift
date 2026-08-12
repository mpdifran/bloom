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
      String(localized: "Monitor Health", bundle: Bundle.coreHealth)
    case .gainWeight:
      String(localized: "Gain Weight", bundle: Bundle.coreHealth)
    case .maintainWeight:
      String(localized: "Maintain Weight", bundle: Bundle.coreHealth)
    case .loseWeight:
      String(localized: "Lose Weight", bundle: Bundle.coreHealth)
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
  @AppStorage(.HealthDefaults.height.key, store: .group) public var heightCM: Double = 0
  @AppStorage(.HealthDefaults.birthMonth.key, store: .group) public var birthMonth: Int = 0
  @AppStorage(.HealthDefaults.birthYear.key, store: .group) public var birthYear: Int = 0

  @Published public var sexKind: HKBiologicalSex = .notSet {
    didSet {
      healthDefaults.setSexKind(sexKind)
      Task { await syncBiologicalSexToWatch() }
    }
  }
  @Published public var focus: String {
    didSet { healthDefaults.set(focus: focus) }
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

  @Published public var smokingStatus: SmokingStatus = .unknown {
    didSet { healthDefaults.setSmokingStatus(smokingStatus) }
  }
  @Published public var smokingQuitDate: Date? {
    didSet { healthDefaults.setSmokingQuitDate(smokingQuitDate) }
  }

  @Published public var heartRateZoneMode: HeartRateZoneCalculationMode = .automatic {
    didSet { healthDefaults.setHeartRateZoneMode(heartRateZoneMode) }
  }
  @Published public var manualMaxHeartRate: Double = 0 {
    didSet { healthDefaults.setManualMaxHeartRate(manualMaxHeartRate) }
  }
  @Published public var manualRestingHeartRate: Double = 0 {
    didSet { healthDefaults.setManualRestingHeartRate(manualRestingHeartRate) }
  }
  @Published public var manualZone1Threshold: Double = 0
  @Published public var manualZone2Threshold: Double = 0
  @Published public var manualZone3Threshold: Double = 0
  @Published public var manualZone4Threshold: Double = 0
  @Published public var manualZone5Threshold: Double = 0

  public var healthTargetDetails: HealthTargetDetails {
    HealthTargetDetails(
      targetWeight: targetWeight,
      goal: focus,
      weightLossSpeed: weightLossSpeed
    )
  }

  @AppStorage(.HealthDefaults.targetWeight.key, store: .group) public var targetWeight: Double = 0
  @AppStorage(.HealthDefaults.isPregnant.key, store: .group) public var isPregnant = false
  @AppStorage(.HealthDefaults.isBreastFeeding.key, store: .group) public var isBreastfeeding = false

  public let healthStore = HKHealthStore()
  let healthDefaults = HealthDefaults.shared

  private init() {
    self.sexKind = healthDefaults.getSexKind()
    self.focus = healthDefaults.getFocus()
    self.weightLossSpeed = healthDefaults.getWeightLossSpeed()
    self.selectedWorkoutEquipment = Set(healthDefaults.getSelectedWorkoutEquipment())
    self.smokingStatus = healthDefaults.getSmokingStatus()
    self.smokingQuitDate = healthDefaults.getSmokingQuitDate()
    self.heartRateZoneMode = healthDefaults.getHeartRateZoneMode()
    self.manualMaxHeartRate = healthDefaults.getManualMaxHeartRate() ?? 0
    self.manualRestingHeartRate = healthDefaults.getManualRestingHeartRate() ?? 0

    if let thresholds = healthDefaults.getManualZoneThresholds() {
      self.manualZone1Threshold = thresholds.zone1
      self.manualZone2Threshold = thresholds.zone2
      self.manualZone3Threshold = thresholds.zone3
      self.manualZone4Threshold = thresholds.zone4
      self.manualZone5Threshold = thresholds.zone5
    }

    if let activityLevel = healthDefaults.getActivityLevel() {
      self.userReportedActivityLevel = activityLevel
    }

    Task {
      await checkHeightFromHealthKit()
    }
  }

  public func saveManualZoneThresholds() {
    healthDefaults.setManualZoneThresholds(
      zone1: manualZone1Threshold,
      zone2: manualZone2Threshold,
      zone3: manualZone3Threshold,
      zone4: manualZone4Threshold,
      zone5: manualZone5Threshold
    )
  }
}

// MARK: Age, Sex, and Height

public extension HealthManager {

  func syncPersonalDataFromHealthKit() async {
    if let sex = healthStore.sex() {
      sexKind = sex
    }

    if let birthday = healthStore.birthday() {
      let components = Calendar.current.dateComponents([.year, .month], from: birthday)
      if let year = components.year {
        birthYear = year
      }
      if let month = components.month {
        birthMonth = month
      }
    } else if birthYear == 0 {
      birthYear = Calendar.current.component(.year, from: .now)
    }

    await checkHeightFromHealthKit()
  }

  func checkHeightFromHealthKit() async {
    if heightCM < 1 {
      let quantity = await HealthStoreFetcher.shared.fetchLatestSample(for: .height)?.quantity
      heightCM = quantity?.doubleValue(for: .meterUnit(with: .centi)) ?? 0
    }
  }

  func age() -> Int {
    guard birthYear > 0 else { return 0 }
    let now = Date.now
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: now)
    let currentMonth = calendar.component(.month, from: now)
    let currentDay = calendar.component(.day, from: now)

    var age = currentYear - birthYear

    // If birth month is set, check if birthday has passed this year
    // We assume the 15th of the month as the birthday when only month is known
    if birthMonth > 0 {
      if currentMonth < birthMonth || (currentMonth == birthMonth && currentDay < 15) {
        age -= 1
      }
    }

    return age
  }

  func sex() -> HKBiologicalSex {
    sexKind
  }

  func height() -> HKQuantity {
    HKQuantity(unit: .meterUnit(with: .centi), doubleValue: heightCM)
  }

  func sexName() -> String {
    sexKind.name
  }

  func targetWeightQuantity() -> HKQuantity {
    HKQuantity(unit: .pound(), doubleValue: targetWeight)
  }
}

// MARK: - Watch Sync

public extension HealthManager {

  func syncBiologicalSexToWatch() async {
    #if os(iOS)
    let watchData = WatchBiologicalSexData(isFemale: sex() == .female)

    guard let data = try? JSONEncoder.watch.encode(watchData) else {
      return
    }

    try? await WatchChannel.shared.updateApplicationContext(
      key: WatchChannel.biologicalSexDataKey,
      data: data
    )
    #endif
  }
}
