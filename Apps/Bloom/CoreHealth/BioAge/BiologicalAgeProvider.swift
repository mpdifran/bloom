//
//  BiologicalAgeProvider.swift
//  CoreHealth
//
//  Created by Claude on 2026-01-26.
//

import Foundation
import BloomFoundation

#if os(watchOS)
/// Provides biological age data on watchOS by reading from WatchConnectivity application context.
@Observable @MainActor
public final class BiologicalAgeProvider {
  public static let shared = BiologicalAgeProvider()

  private static let biologicalAgeKey = "BiologicalAgeProvider.biologicalAge"
  private static let actualAgeKey = "BiologicalAgeProvider.actualAge"
  private static let lastCalculatedKey = "BiologicalAgeProvider.lastCalculated"

  public private(set) var biologicalAge: Double? {
    didSet { saveToUserDefaults() }
  }
  public private(set) var actualAge: Double? {
    didSet { saveToUserDefaults() }
  }
  public private(set) var lastCalculated: Date? {
    didSet { saveToUserDefaults() }
  }

  /// Use synced actualAge - HealthDefaults uses UserDefaults which is not available on watchOS
  public var chronologicalAge: Double {
    actualAge ?? 0
  }

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

  private func loadFromUserDefaults() {
    biologicalAge = UserDefaults.standard.object(forKey: Self.biologicalAgeKey) as? Double
    actualAge = UserDefaults.standard.object(forKey: Self.actualAgeKey) as? Double
    if let timestamp = UserDefaults.standard.object(forKey: Self.lastCalculatedKey) as? Double {
      lastCalculated = Date(timeIntervalSince1970: timestamp)
    }
  }

  private func saveToUserDefaults() {
    if let biologicalAge {
      UserDefaults.standard.set(biologicalAge, forKey: Self.biologicalAgeKey)
    }
    if let actualAge {
      UserDefaults.standard.set(actualAge, forKey: Self.actualAgeKey)
    }
    if let lastCalculated {
      UserDefaults.standard.set(lastCalculated.timeIntervalSince1970, forKey: Self.lastCalculatedKey)
    }
  }

  @objc private func handleApplicationContextUpdate() {
    loadFromApplicationContext()
  }

  /// Loads biological age data from WatchConnectivity application context
  public func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.biologicalAgeKey),
          let watchData = try? JSONDecoder().decode(WatchBiologicalAgeData.self, from: data) else {
      return
    }

    biologicalAge = watchData.biologicalAge
    actualAge = watchData.actualAge
    lastCalculated = watchData.lastCalculated
  }
}
#endif
