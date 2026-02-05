//
//  BiologicalAgeViewModel.swift
//  Bloom
//
//  Created by Assistant on 2025-09-15.
//

import Foundation
import CoreHealth
import BloomFoundation
import TelemetryDeck

@MainActor @Observable
final class BiologicalAgeViewModel {
  static let shared = BiologicalAgeViewModel()

  private(set) var biologicalAgeResult: BiologicalAgeResult?
  var isCalculatingAge = false

  private var observationTask: Task<Void, Never>?

  private init() {
    startObservingBiologicalAge()
    loadLatestResult()
  }

  private func loadLatestResult() {
    Task {
      await BiologicalAgeCalculator.shared.loadLatestResult()
    }
  }

  private func startObservingBiologicalAge() {
    observationTask = Task {
      for await result in await BiologicalAgeCalculator.shared.$biologicalAge {
        await MainActor.run {
          self.biologicalAgeResult = result
        }
      }
    }
  }

  // MARK: - Mock Support

  private var mockBioAgeEnabled: Bool {
    UserDefaults.standard.bool(forKey: String.FeatureFlag.mockBioAgeEnabled)
  }

  private var mockBioAgeDelta: Double {
    UserDefaults.standard.double(forKey: String.FeatureFlag.mockBioAgeDelta)
  }

  /// Returns the bio age result with mock applied if enabled in developer settings
  var displayBiologicalAgeResult: BiologicalAgeResult? {
    guard let result = biologicalAgeResult else { return nil }
    guard mockBioAgeEnabled else { return result }

    let mockedBioAge = result.actualAge + mockBioAgeDelta
    let clamped = max(result.actualAge - 12, min(result.actualAge + 12, mockedBioAge))

    return BiologicalAgeResult(
      biologicalAge: clamped,
      actualAge: result.actualAge,
      lastCalculated: result.lastCalculated,
      metricContributions: result.metricContributions
    )
  }
}

extension BiologicalAgeViewModel {

  var currentBiologicalAge: Double? {
    displayBiologicalAgeResult?.biologicalAge
  }

  func calculateBiologicalAgeIfNeeded() async {
    guard !isCalculatingAge else { return }

    isCalculatingAge = true
    defer { isCalculatingAge = false }

    await BiologicalAgeCalculator.shared.refreshBiologicalAge()

    if let result = await BiologicalAgeCalculator.shared.biologicalAge {
      TelemetryDeck.signal(
        "Biological Age Calculated",
        parameters: [
          "biologicalAge": String(result.biologicalAge)
        ]
      )
    }
  }

  func forceCalculateBiologicalAge() async {
    guard !isCalculatingAge else { return }

    isCalculatingAge = true
    defer { isCalculatingAge = false }

    await BiologicalAgeCalculator.shared.refreshBiologicalAge(forceRecalculate: true)

    if let result = await BiologicalAgeCalculator.shared.biologicalAge {
      TelemetryDeck.signal(
        "Biological Age Calculated",
        parameters: [
          "biologicalAge": String(result.biologicalAge)
        ]
      )
    }
  }
}
