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

    let cameraManager: CameraManager
    let captureSession = AVCaptureSession()

    init() {
      self.cameraManager = CameraManager.create(with: captureSession)

      setupObservers()
    }

    private var tasks = [Task<Void, Never>]()
  }
}

extension AIFoodScannerView.ViewModel {

  private func setupObservers() {
    tasks.removeAll(keepingCapacity: true)

    tasks.append(Task.detached {
      for await barcode in await self.cameraManager.$detectedBarcode {
        await MainActor.run {
          self.detectedBarcode = barcode
        }
      }
    })
  }

  func captureImage() {
    Task.detached { [weak self] in
      await self?.performCaptureImage()
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

private extension AIFoodScannerView.ViewModel {

  nonisolated func performCaptureImage() async {
    guard let image = await cameraManager.capture() else { return } // TODO: Throw error?

    await MainActor.run {
      self.image = image
    }

    await performAIFoodLog(for: image)
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
