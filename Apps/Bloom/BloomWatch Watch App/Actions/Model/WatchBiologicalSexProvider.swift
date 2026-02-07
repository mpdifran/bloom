//
//  WatchBiologicalSexProvider.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-02-06.
//

import Foundation
import BloomFoundation

/// Provides biological sex on watchOS by reading from WatchConnectivity application context.
@Observable @MainActor
final class WatchBiologicalSexProvider {
  static let shared = WatchBiologicalSexProvider()

  private static let isFemaleKey = "WatchBiologicalSexProvider.isFemale"

  private(set) var isFemale: Bool = false {
    didSet { saveToUserDefaults() }
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

  @objc private func handleApplicationContextUpdate() {
    loadFromApplicationContext()
  }

  func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.biologicalSexDataKey),
          let sexData = try? JSONDecoder.watch.decode(WatchBiologicalSexData.self, from: data) else {
      return
    }

    isFemale = sexData.isFemale
  }

  private func loadFromUserDefaults() {
    isFemale = UserDefaults.group.bool(forKey: Self.isFemaleKey)
  }

  private func saveToUserDefaults() {
    UserDefaults.group.set(isFemale, forKey: Self.isFemaleKey)
  }
}
