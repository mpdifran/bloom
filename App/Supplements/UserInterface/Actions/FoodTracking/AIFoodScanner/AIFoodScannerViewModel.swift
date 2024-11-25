//
//  AIFoodScannerViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-24.
//

import SwiftUI
import BloomModel
import DataContainer

@Observable @MainActor
final class AIFoodScannerViewModel {

    var isLoading = false
    var servings = [FoodItemServing]()
    var error: Error?
}

extension AIFoodScannerViewModel {

    func performAIFoodLog(for image: UIImage) async {
        guard let smallerImage = image.resized(toWidth: 800) else { return }

        do {
            isLoading = true
            let response = try await NetworkRequester.shared.foodAIEstimate(image: smallerImage)

            self.servings = response.servings.map({ $0.asServing() })
            isLoading = false
        } catch {
            self.error = error
        }
    }
}
