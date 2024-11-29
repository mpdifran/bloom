//
//  AIFoodScannerViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-24.
//

import SwiftUI
import BloomModel
import DataContainer
import TelemetryDeck

extension AIFoodScannerView {
    @Observable @MainActor
    final class ViewModel {
        var image: UIImage?
        var hasScannedAtLeastOnce = false
        var isLoading = false
        var servings = [FoodItemServing]()
        var error: Error?
    }
}

extension AIFoodScannerView.ViewModel {

    func performAIFoodLog(for image: UIImage) async {
        guard let smallerImage = image.resized(toWidth: 800) else { return }

        do {
            hasScannedAtLeastOnce = true
            isLoading = true
            let response = try await NetworkRequester.shared.foodAIEstimate(image: smallerImage)

            self.servings = response.servings.map({ $0.asServing() })
            isLoading = false

            if servings.isEmpty {
                self.image = nil
            } else {
                TelemetryDeck.signal("AI Food Scan", floatValue: Double(servings.count))
            }
        } catch {
            self.error = error
        }
    }

    func reset() {
        hasScannedAtLeastOnce = false
        image = nil
        isLoading = false
        error = nil
        servings.removeAll()
    }
}
