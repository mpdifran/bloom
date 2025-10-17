//
//  AIFoodTextGenerationViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-06.
//

import SwiftUI
import TelemetryDeck
import CoreNetwork

extension AIFoodTextGenerationView {
  @MainActor @Observable
  final class ViewModel {
    var foodName: String?
    var servings = [FoodItemServingAmount]()
    var suggestedServings = [FoodItemServingAmount]()
    var isEstimating = false
  }
}

extension AIFoodTextGenerationView.ViewModel {

  func resetResults() {
    foodName = nil
    servings.removeAll()
    suggestedServings.removeAll()
    isEstimating = false
  }

  nonisolated func estimateFood(for foodDescription: String) async throws {
    guard foodDescription.isNotEmpty else { return }

    defer {
      Task { await MainActor.run { isEstimating = false } }
    }

    await MainActor.run {
      isEstimating = true
    }

    do {
      let response = try await NetworkRequester.shared.foodAITextEstimate(foodDescription: foodDescription)

      let newServings = response.servings.map { $0.asServing() }
      let newSuggestedServings = response.suggestedServings.map { $0.asServing() }

      await MainActor.run {
        self.foodName = response.name
        self.servings = newServings
        self.suggestedServings = newSuggestedServings
        self.isEstimating = false
        TelemetryDeck.signal("Food Item AI Text Generation", parameters: ["AITextGenerationResult": "Success"])
      }
    } catch {
      TelemetryDeck.signal("Food Item AI Text Generation", parameters: ["AITextGenerationResult": "Fail"])
      TelemetryDeck.errorOccurred(
        id: "AIFoodTextGenerationView.ViewModel.estimateFood",
        category: .thrownException,
        message: error.localizedDescription
      )
      throw error
    }
  }
}
