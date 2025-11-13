//
//  BiologicalAgeStatusChecker.swift
//  Bloom
//
//  Created by Claude Code
//

import Foundation
import CoreNetwork
import TelemetryDeck
import BloomModel

@MainActor
final class BiologicalAgeStatusChecker {
  static let shared = BiologicalAgeStatusChecker()

  private init() {}

  /// Checks if there's a pending biological age calculation
  func checkPendingCalculation() async {
    // Only check status if we have a pending calculation
    guard BiologicalAgeViewModel.shared.hasPendingCalculation else {
      return
    }

    do {
      let response = try await NetworkRequester.shared.checkBiologicalAgeStatus()

      await handleStatusResponse(response)
    } catch {
      TelemetryDeck.errorOccurred(
        id: "BiologicalAgeStatusChecker.checkPendingCalculation",
        category: .thrownException,
        message: error.localizedDescription
      )
      print("Error checking biological age status:", error)
    }
  }

  private func handleStatusResponse(_ response: BiologicalAgeStatusResponse) async {
    switch response.status {
    case .completed:
      // Store result in UserDefaults if available
      if let result = response.result {
        BiologicalAgeViewModel.shared.storeCalculationResult(result)
        TelemetryDeck.signal("BiologicalAge.CalculationCompleted")
      }

    case .failed:
      let errorMessage = response.errorMessage ?? "Calculation failed"
      BiologicalAgeViewModel.shared.clearPendingCalculation()
      TelemetryDeck.errorOccurred(
        id: "BiologicalAge.CalculationFailed",
        category: .thrownException,
        message: errorMessage
      )
      print("Biological age calculation failed:", errorMessage)

    case .pending, .processing:
      // Still processing, nothing to do
      break

    case .notFound:
      // No job found - clear the pending flag
      BiologicalAgeViewModel.shared.clearPendingCalculation()
      break
    }
  }
}
