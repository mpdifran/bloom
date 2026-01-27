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

  public private(set) var biologicalAge: Double?
  public private(set) var actualAge: Double?
  public private(set) var lastCalculated: Date?

  /// Use synced actualAge - HealthDefaults uses UserDefaults which is not available on watchOS
  public var chronologicalAge: Double {
    actualAge ?? 0
  }

  private init() {
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
