//
//  BiologicalAgeViewModel.swift
//  Bloom
//
//  Created by Assistant on 2025-09-15.
//

import Foundation
import CoreHealth
import DataContainer
import BloomModel
import BloomFoundation
import TelemetryDeck
import SwiftData
import CoreNetwork
import BloomUI

private extension String {
  static let lastBiologicalAgeRequestDate = "BiologicalAgeViewModel.lastBiologicalAgeRequestDate"
  static let lastBiologicalAgeResponse = "BiologicalAgeViewModel.lastBiologicalAgeResponse"
  static let hasPendingBiologicalAgeCalculation = "BiologicalAgeViewModel.hasPendingBiologicalAgeCalculation"
}

@MainActor @Observable
final class BiologicalAgeViewModel {
  static let shared = BiologicalAgeViewModel()

  private var lastRequestDate: Date? {
    didSet {
      UserDefaults.group.set(lastRequestDate, forKey: .lastBiologicalAgeRequestDate)
    }
  }

  private var lastResponse: BiologicalAgeResponse? {
    didSet {
      if let response = lastResponse {
        if let data = try? JSONEncoder().encode(response) {
          UserDefaults.group.set(data, forKey: .lastBiologicalAgeResponse)
        }
      } else {
        UserDefaults.group.removeObject(forKey: .lastBiologicalAgeResponse)
      }
    }
  }

  var hasPendingCalculation: Bool {
    didSet {
      UserDefaults.group.set(hasPendingCalculation, forKey: .hasPendingBiologicalAgeCalculation)
    }
  }

  var isCalculatingAge = false
  var lastCalculationError: Error? = nil

  private init() {
    self.hasPendingCalculation = UserDefaults.group.bool(forKey: .hasPendingBiologicalAgeCalculation)

    if let date = UserDefaults.group.object(forKey: .lastBiologicalAgeRequestDate) as? Date {
      self.lastRequestDate = date
    }

    if let data = UserDefaults.group.data(forKey: .lastBiologicalAgeResponse),
       let response = try? JSONDecoder().decode(BiologicalAgeResponse.self, from: data) {
      self.lastResponse = response
    }
  }
}

extension BiologicalAgeViewModel {

  var currentBiologicalAge: Double? {
    lastResponse?.biologicalAge
  }

  var lastCalculatedResponse: BiologicalAgeResponse? {
    lastResponse
  }

  func shouldCalculateBiologicalAge() -> Bool {
    // Check if we have made a request in the last 7 days
    guard let lastRequest = lastRequestDate else { return true }

    let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    return lastRequest < sevenDaysAgo
  }

  func calculateBiologicalAgeIfNeeded() async {
    guard shouldCalculateBiologicalAge() else { return }
    guard !isCalculatingAge else { return }

    await calculateAndStoreBiologicalAge()
  }

  func forceCalculateBiologicalAge() async {
    guard !isCalculatingAge else { return }
    await calculateAndStoreBiologicalAge()
  }

  private func calculateAndStoreBiologicalAge() async {
    guard EntitlementController.shared.hasBloomPro == true else { return }

    // Privacy check: Don't calculate if biological age feature is disabled
    guard await AIFeatureSettings.shared.biologicalAgeEnabled else { return }

    isCalculatingAge = true
    lastCalculationError = nil

    defer {
      isCalculatingAge = false
    }

    do {
      let today = Date()

      // Collect health data using BiologicalAgeHealthContextCalculator
      let calculator = BiologicalAgeHealthContextCalculator()
      let healthData = try await calculator.collectBiologicalAgeData()

      // Convert health data to JSON string
      let healthContext: String
      do {
        let data = try JSONEncoder().encode(healthData)
        healthContext = String(data: data, encoding: .utf8) ?? "{}"
      } catch {
        TelemetryDeck.errorOccurred(
          id: "BiologicalAgeManager.healthDataEncoding",
          category: .thrownException,
          message: error.localizedDescription
        )
        healthContext = "{}"
      }

      // Fetch current age from HealthKit
      let currentAge = await calculator.fetchCurrentAge()

      // Get last biological age from previous calculation
      let lastBioAge = lastResponse?.biologicalAge

      // Create request with health data, current age, and last biological age
      let request = BiologicalAgeUploadRequest(
        healthContext: healthContext,
        currentAge: currentAge,
        lastBiologicalAge: lastBioAge
      )

      // Make network request to start background calculation
      let uploadResponse: BiologicalAgeUploadResponse
      do {
        uploadResponse = try await NetworkRequester.shared.requestBiologicalAge(request: request)
      } catch {
        TelemetryDeck.signal(
          "Biological Age Network Error",
          parameters: ["errorMessage": error.localizedDescription]
        )
        throw error
      }

      // Record that we made a request
      lastRequestDate = today
      hasPendingCalculation = true

      TelemetryDeck.signal(
        "Biological Age Requested",
        parameters: [
          "status": uploadResponse.status.rawValue
        ]
      )

      // If the response is already completed (shouldn't happen but handle it)
      if uploadResponse.status == .completed {
        // Check for the result immediately
        await BiologicalAgeStatusChecker.shared.checkPendingCalculation()
      }

    } catch {
      lastCalculationError = error
      TelemetryDeck.errorOccurred(
        id: "BiologicalAgeViewModel.calculateAndStoreBiologicalAge",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }

  /// Stores a completed calculation result (called by BiologicalAgeStatusChecker)
  func storeCalculationResult(_ response: BiologicalAgeResponse) {
    lastResponse = response
    hasPendingCalculation = false

    TelemetryDeck.signal(
      "Biological Age Calculated",
      parameters: [
        "biologicalAge": String(response.biologicalAge)
      ]
    )
  }

  /// Clears the pending calculation flag (called by BiologicalAgeStatusChecker on failure or notFound)
  func clearPendingCalculation() {
    hasPendingCalculation = false
  }
}
