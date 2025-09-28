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

private extension String {
  static let lastBiologicalAgeRequestDate = "BiologicalAgeViewModel.lastBiologicalAgeRequestDate"
  static let lastBiologicalAgeResponse = "BiologicalAgeViewModel.lastBiologicalAgeResponse"
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

  var isCalculatingAge = false
  var lastCalculationError: Error? = nil

  private init() {
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
    // Check if we have made a request in the last 3 days
    guard let lastRequest = lastRequestDate else { return true }

    let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    return lastRequest < threeDaysAgo
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

      // Create simplified request with only health data
      let request = BiologicalAgeRequest(healthContext: healthContext)

      // Make network request
      let response: BiologicalAgeResponse
      do {
        response = try await NetworkRequester.shared.getBiologicalAge(request: request)
      } catch {
        TelemetryDeck.signal(
          "Biological Age Network Error",
          parameters: ["errorMessage": error.localizedDescription]
        )
        throw error
      }

      // Store the response
      lastResponse = response
      lastRequestDate = today

      TelemetryDeck.signal(
        "Biological Age Calculated",
        parameters: [
          "biologicalAge": String(response.biologicalAge)
        ]
      )

    } catch {
      lastCalculationError = error
      TelemetryDeck.errorOccurred(
        id: "BiologicalAgeViewModel.calculateAndStoreBiologicalAge",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }
}
