//
//  WatchHeartRateZoneSettingsSyncer.swift
//  Bloom
//
//  Created by Claude on 2026-02-05.
//

import Foundation
import BloomFoundation
import CoreHealth

/// Syncs heart rate zone settings to the Apple Watch
@MainActor
final class WatchHeartRateZoneSettingsSyncer {
  static let shared = WatchHeartRateZoneSettingsSyncer()

  private init() {}

  /// Syncs heart rate zone settings to watch via application context.
  /// Sends resolved zone thresholds (computed based on current mode) so the watch
  /// always has usable zone values for workouts.
  func syncToWatch() async {
    #if os(iOS)
    let healthManager = HealthManager.shared

    // Compute resolved zones based on mode (automatic, semiManual, manual)
    let resolvedZones = await HealthStoreFetcher.shared.heartRateZones()

    let watchData: WatchHeartRateZoneSettingsData
    if let zones = resolvedZones {
      watchData = WatchHeartRateZoneSettingsData(
        mode: healthManager.heartRateZoneMode.rawValue,
        maxHeartRate: zones.maxHeartRate,
        restingHeartRate: zones.restingHeartRate,
        zone1Threshold: zones.zone1,
        zone2Threshold: zones.zone2,
        zone3Threshold: zones.zone3,
        zone4Threshold: zones.zone4,
        zone5Threshold: zones.zone5
      )
    } else {
      // Fallback to manual values if resolved zones unavailable (e.g. no HealthKit data in automatic mode)
      watchData = WatchHeartRateZoneSettingsData(
        mode: healthManager.heartRateZoneMode.rawValue,
        maxHeartRate: healthManager.manualMaxHeartRate,
        restingHeartRate: healthManager.manualRestingHeartRate,
        zone1Threshold: healthManager.manualZone1Threshold,
        zone2Threshold: healthManager.manualZone2Threshold,
        zone3Threshold: healthManager.manualZone3Threshold,
        zone4Threshold: healthManager.manualZone4Threshold,
        zone5Threshold: healthManager.manualZone5Threshold
      )
    }

    guard let data = try? JSONEncoder.watch.encode(watchData) else {
      print("Failed to encode watch HRZ settings data")
      return
    }

    do {
      try await WatchChannel.shared.updateApplicationContext(
        key: WatchChannel.heartRateZoneSettingsKey,
        data: data
      )
    } catch {
      print("Failed to sync HRZ settings to watch: \(error)")
    }
    #endif
  }

  /// Handles incoming HRZ settings message from watch and updates iOS settings
  func handleSettingsFromWatch(_ message: WatchHeartRateZoneSettingsMessage) async -> Bool {
    let healthManager = HealthManager.shared

    // Update mode
    if let mode = HeartRateZoneCalculationMode(rawValue: message.mode) {
      healthManager.heartRateZoneMode = mode
    }

    // Update manual heart rate values
    if message.maxHeartRate > 0 {
      healthManager.manualMaxHeartRate = message.maxHeartRate
    }
    if message.restingHeartRate > 0 {
      healthManager.manualRestingHeartRate = message.restingHeartRate
    }

    // Update zone thresholds
    if message.zone1Threshold > 0 {
      healthManager.manualZone1Threshold = message.zone1Threshold
    }
    if message.zone2Threshold > 0 {
      healthManager.manualZone2Threshold = message.zone2Threshold
    }
    if message.zone3Threshold > 0 {
      healthManager.manualZone3Threshold = message.zone3Threshold
    }
    if message.zone4Threshold > 0 {
      healthManager.manualZone4Threshold = message.zone4Threshold
    }
    if message.zone5Threshold > 0 {
      healthManager.manualZone5Threshold = message.zone5Threshold
    }

    // Save thresholds if in manual mode
    if healthManager.heartRateZoneMode == .manual {
      healthManager.saveManualZoneThresholds()
    }

    // Sync updated settings back to watch to confirm
    await syncToWatch()

    return true
  }
}
