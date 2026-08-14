//
//  HeartRateZoneSettingsProvider.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-05.
//

import Foundation
import BloomFoundation
import CoreHealth

@Observable @MainActor
public final class HeartRateZoneSettingsProvider {
  public static let shared = HeartRateZoneSettingsProvider()

  // MARK: - User Defaults Keys

  private static let modeKey = "HeartRateZoneSettingsProvider.mode"
  private static let maxHeartRateKey = "HeartRateZoneSettingsProvider.maxHeartRate"
  private static let restingHeartRateKey = "HeartRateZoneSettingsProvider.restingHeartRate"
  private static let zone1Key = "HeartRateZoneSettingsProvider.zone1"
  private static let zone2Key = "HeartRateZoneSettingsProvider.zone2"
  private static let zone3Key = "HeartRateZoneSettingsProvider.zone3"
  private static let zone4Key = "HeartRateZoneSettingsProvider.zone4"
  private static let zone5Key = "HeartRateZoneSettingsProvider.zone5"

  // MARK: - Published Properties

  public var mode: HeartRateZoneMode = .automatic {
    didSet {
      UserDefaults.group.set(mode.rawValue, forKey: Self.modeKey)
      sendSettingsToiOS()
    }
  }

  public var maxHeartRate: Double = 185 {
    didSet {
      UserDefaults.group.set(maxHeartRate, forKey: Self.maxHeartRateKey)
      sendSettingsToiOS()
    }
  }

  public var restingHeartRate: Double = 60 {
    didSet {
      UserDefaults.group.set(restingHeartRate, forKey: Self.restingHeartRateKey)
      sendSettingsToiOS()
    }
  }

  public var zone1Threshold: Double = 110 {
    didSet {
      UserDefaults.group.set(zone1Threshold, forKey: Self.zone1Key)
      sendSettingsToiOS()
    }
  }

  public var zone2Threshold: Double = 125 {
    didSet {
      UserDefaults.group.set(zone2Threshold, forKey: Self.zone2Key)
      sendSettingsToiOS()
    }
  }

  public var zone3Threshold: Double = 140 {
    didSet {
      UserDefaults.group.set(zone3Threshold, forKey: Self.zone3Key)
      sendSettingsToiOS()
    }
  }

  public var zone4Threshold: Double = 155 {
    didSet {
      UserDefaults.group.set(zone4Threshold, forKey: Self.zone4Key)
      sendSettingsToiOS()
    }
  }

  public var zone5Threshold: Double = 170 {
    didSet {
      UserDefaults.group.set(zone5Threshold, forKey: Self.zone5Key)
      sendSettingsToiOS()
    }
  }

  public var isSendingToiOS = false

  // MARK: - Computed Properties

  public var modeDisplayName: String {
    mode.displayName
  }

  public var modeDescription: String {
    mode.description
  }

  public func buildHeartRateZones() -> HeartRateZones {
    HeartRateZones(
      heartRateReserve: maxHeartRate - restingHeartRate,
      restingHeartRate: restingHeartRate,
      maxHeartRate: maxHeartRate,
      zone1: zone1Threshold,
      zone2: zone2Threshold,
      zone3: zone3Threshold,
      zone4: zone4Threshold,
      zone5: zone5Threshold
    )
  }

  // MARK: - Initialization

  private init() {
    loadFromUserDefaults()
    loadFromApplicationContext()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleApplicationContextUpdate),
      name: WatchChannel.applicationContextDidUpdate,
      object: nil
    )
  }

  // MARK: - Loading

  private func loadFromUserDefaults() {
    if let modeString = UserDefaults.group.string(forKey: Self.modeKey),
       let savedMode = HeartRateZoneMode(rawValue: modeString) {
      mode = savedMode
    }

    let savedMaxHR = UserDefaults.group.double(forKey: Self.maxHeartRateKey)
    if savedMaxHR > 0 {
      maxHeartRate = savedMaxHR
    }

    let savedRestingHR = UserDefaults.group.double(forKey: Self.restingHeartRateKey)
    if savedRestingHR > 0 {
      restingHeartRate = savedRestingHR
    }

    let savedZone1 = UserDefaults.group.double(forKey: Self.zone1Key)
    if savedZone1 > 0 { zone1Threshold = savedZone1 }

    let savedZone2 = UserDefaults.group.double(forKey: Self.zone2Key)
    if savedZone2 > 0 { zone2Threshold = savedZone2 }

    let savedZone3 = UserDefaults.group.double(forKey: Self.zone3Key)
    if savedZone3 > 0 { zone3Threshold = savedZone3 }

    let savedZone4 = UserDefaults.group.double(forKey: Self.zone4Key)
    if savedZone4 > 0 { zone4Threshold = savedZone4 }

    let savedZone5 = UserDefaults.group.double(forKey: Self.zone5Key)
    if savedZone5 > 0 { zone5Threshold = savedZone5 }
  }

  @objc private func handleApplicationContextUpdate() {
    loadFromApplicationContext()
  }

  public func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.heartRateZoneSettingsKey),
          let watchData = try? JSONDecoder.watch.decode(WatchHeartRateZoneSettingsData.self, from: data) else {
      return
    }

    // Update without triggering didSet sends back to iOS
    updateWithoutSync {
      if let newMode = HeartRateZoneMode(rawValue: watchData.mode) {
        mode = newMode
      }
      maxHeartRate = watchData.maxHeartRate
      restingHeartRate = watchData.restingHeartRate
      zone1Threshold = watchData.zone1Threshold
      zone2Threshold = watchData.zone2Threshold
      zone3Threshold = watchData.zone3Threshold
      zone4Threshold = watchData.zone4Threshold
      zone5Threshold = watchData.zone5Threshold
    }

    // Persist to UserDefaults
    UserDefaults.group.set(mode.rawValue, forKey: Self.modeKey)
    UserDefaults.group.set(maxHeartRate, forKey: Self.maxHeartRateKey)
    UserDefaults.group.set(restingHeartRate, forKey: Self.restingHeartRateKey)
    UserDefaults.group.set(zone1Threshold, forKey: Self.zone1Key)
    UserDefaults.group.set(zone2Threshold, forKey: Self.zone2Key)
    UserDefaults.group.set(zone3Threshold, forKey: Self.zone3Key)
    UserDefaults.group.set(zone4Threshold, forKey: Self.zone4Key)
    UserDefaults.group.set(zone5Threshold, forKey: Self.zone5Key)
  }

  // MARK: - Sync to iOS

  private var isSyncing = false

  private func updateWithoutSync(_ block: () -> Void) {
    isSyncing = true
    block()
    isSyncing = false
  }

  private func sendSettingsToiOS() {
    guard !isSyncing else { return }

    let message = WatchHeartRateZoneSettingsMessage(
      mode: mode.rawValue,
      maxHeartRate: maxHeartRate,
      restingHeartRate: restingHeartRate,
      zone1Threshold: zone1Threshold,
      zone2Threshold: zone2Threshold,
      zone3Threshold: zone3Threshold,
      zone4Threshold: zone4Threshold,
      zone5Threshold: zone5Threshold
    )

    Task {
      await MainActor.run { isSendingToiOS = true }
      defer { Task { @MainActor in isSendingToiOS = false } }

      guard let data = try? JSONEncoder.watch.encode(message) else { return }

      do {
        _ = try await WatchChannel.shared.send(data: data)
      } catch {
        print("Failed to send HRZ settings to iOS: \(error)")
      }
    }
  }
}

// MARK: - HeartRateZoneMode

public enum HeartRateZoneMode: String, CaseIterable, Sendable {
  case automatic
  case semiManual
  case manual

  public var displayName: String {
    switch self {
    case .automatic: return String(localized: "Automatic", comment: "Display name for heart rate zone mode")
    case .semiManual: return String(localized: "Custom HR", comment: "Display name for heart rate zone mode")
    case .manual: return String(localized: "Custom Zones", comment: "Display name for heart rate zone mode")
    }
  }

  public var description: String {
    switch self {
    case .automatic:
      return String(localized: "Zones calculated from your age and resting heart rate", comment: "Description for heart rate zone mode")
    case .semiManual:
      return String(localized: "Set your max and resting HR, zones calculated automatically", comment: "Description for heart rate zone mode")
    case .manual:
      return String(localized: "Set each zone threshold individually", comment: "Description for heart rate zone mode")
    }
  }
}
