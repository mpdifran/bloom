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
import AVFoundation

extension AIFoodScannerView {
  @Observable @MainActor
  final class ViewModel {
    var image: UIImage?
    var hasScannedAtLeastOnce = false
    var isLoading = false
    var detectedBarcode: String?
    var servings = [FoodItemServing]()
    var error: Error?

    init() {
      setupObservers()
    }

    private var tasks = [Task<Void, Never>]()
  }
}

extension AIFoodScannerView.ViewModel {

  private func setupObservers() {
//    tasks.removeAll(keepingCapacity: true)
//
//    tasks.append(Task.detached {
//      for await barcode in await self.cameraManager.$detectedBarcode {
//        await MainActor.run {
//          self.detectedBarcode = barcode
//        }
//      }
//    })
  }

  func reset() {
    hasScannedAtLeastOnce = false
    image = nil
    isLoading = false
    error = nil
    servings.removeAll()
  }

  nonisolated func performAIFoodLog(for image: UIImage) async {
    guard let smallerImage = image.resized(toWidth: 1200) else { return }

    do {
      await MainActor.run {
        hasScannedAtLeastOnce = true
        isLoading = true
      }

      let response = try await NetworkRequester.shared.foodAIEstimate(image: smallerImage)
      let servings = response.servings.map({ $0.asServing() })

      await MainActor.run {
        self.servings = servings
        self.isLoading = false

        if servings.isEmpty {
          self.image = nil
        } else {
          TelemetryDeck.signal("AI Food Scan", floatValue: Double(servings.count))
        }
      }
    } catch {
      await MainActor.run {
        self.error = error
        print(error)
        self.isLoading = false
        self.image = nil
      }
    }
  }
}
