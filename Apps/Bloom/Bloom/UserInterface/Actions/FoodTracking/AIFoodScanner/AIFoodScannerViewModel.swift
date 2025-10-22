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
import CoreNetwork
import CoreHealth

extension AIFoodScannerView {
  @Observable @MainActor
  final class ViewModel {
    var mode: Mode = .base
    var image: UIImage?
    var scannedFoodName: String?
    var servings = [FoodItemServingAmount]()
    var suggestedServings = [FoodItemServingAmount]()
    var scanResultsToggle = false
    var scanResultsErrorToggle = false
    var error: Error?

    let cameraManager = CameraManager()
  }
}

extension AIFoodScannerView.ViewModel {

  func reset() {
    image = nil
    mode = .base
    error = nil
    scannedFoodName = nil
    servings.removeAll()
    suggestedServings.removeAll()
  }

  func takePhoto() async {
    mode = .aiScanLoading

    Task.detached { [weak self] in
      guard let self else { return }

      await self.performTakePhoto()
    }
  }
}

private extension AIFoodScannerView.ViewModel {

  nonisolated func performTakePhoto() async {
    guard let image = await cameraManager.capture() else {
      await MainActor.run { mode = .base }
      return
    } // TODO: Throw error?

    await MainActor.run {
      self.image = image
    }

    await performAIFoodLog(for: image)
  }

  nonisolated func performAIFoodLog(for image: UIImage) async {
    guard let smallerImage = image.resized(toWidth: 600) else {
      await MainActor.run { mode = .base }
      return
    }

    do {
      let response = try await NetworkRequester.shared.foodAIEstimate(image: smallerImage, foodDescription: nil)
      let newServings = response.servings.map { $0.asServing() }
      let newSuggestedServings = response.suggestedServings.map { $0.asServing() }

      await MainActor.run {
        self.scannedFoodName = response.name
        self.servings = newServings + servings
        self.suggestedServings = newSuggestedServings + suggestedServings

        if servings.isEmpty {
          self.image = nil
          self.suggestedServings = []
          self.scannedFoodName = nil
          self.mode = .base
        } else {
          TelemetryDeck.signal("AI Food Scan", floatValue: Double(servings.count))
          scanResultsToggle.toggle()
          self.mode = .aiScanResults
        }
      }
    } catch {
      await MainActor.run {
        self.error = error
        print(error)
        self.image = nil
        self.mode = .base
      }
    }
  }
}
