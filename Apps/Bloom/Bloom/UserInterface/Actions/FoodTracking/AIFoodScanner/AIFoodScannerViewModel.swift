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
    var scannedFoodName: String?
    var servings = [FoodItemServing]()
    var suggestedServings = [FoodItemServing]()
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
    scannedFoodName = nil
    servings.removeAll()
    suggestedServings.removeAll()
  }

  nonisolated func performAIFoodLog(for image: UIImage) async {
    guard let smallerImage = image.resized(toWidth: 1200) else { return }

    do {
      await MainActor.run {
        hasScannedAtLeastOnce = true
        isLoading = true
      }

      let response = try await NetworkRequester.shared.foodAIEstimate(image: smallerImage)
      let servings = response.servings.map { $0.asServing() }
      let suggestedServings = response.suggestedServings.map { $0.asServing() }

      await MainActor.run {
        self.scannedFoodName = response.name
        self.servings = servings
        self.suggestedServings = suggestedServings
        self.isLoading = false

        if servings.isEmpty {
          self.image = nil
          self.suggestedServings = []
          self.scannedFoodName = nil
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
