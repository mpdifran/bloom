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

extension AIFoodScannerView {
  @Observable @MainActor
  final class ViewModel {
    var mode: Mode = .base
    var image: UIImage?
    var scannedFoodName: String?
    var servings = [FoodItemServingAmount]()
    var suggestedServings = [FoodItemServingAmount]()
    var unknownBarcodes = [String]()
    var scanResultsToggle = false
    var scanResultsErrorToggle = false
    var country: String = "usa"
    var error: Error?

    init() {
      setupObservers()
    }

    let cameraManager = CameraManager()

    private var detectedBarcodes = Set<String>()
    private var tasks = [Task<Void, Never>]()
  }
}

extension AIFoodScannerView.ViewModel {

  private func setupObservers() {
    cameraManager.onNewBarcode = { [weak self] barcode in
      Task {
        await self?.handleNewBarcode(barcode)
      }
    }
  }

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

  func added(foodItem: FoodItem, for barcode: String) {
    unknownBarcodes.removeAll(where: { $0 == barcode })

    let serving = FoodItemServingAmount(serving: 1, foodItem: foodItem)
    servings.append(serving)
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

  func handleNewBarcode(_ barcode: String) async {
    guard mode == .base else { return }
    guard !detectedBarcodes.contains(barcode) else { return }

    detectedBarcodes.insert(barcode)

    let foodItems = await search(barcode: barcode)
    let barcodeServings = foodItems.map { FoodItemServingAmount(serving: 1, foodItem: $0) }

    if barcodeServings.isEmpty {
      scanResultsErrorToggle.toggle()
      unknownBarcodes.append(barcode)
      TelemetryDeck.signal("Food Item Barcode Scan", parameters: ["barcodeScanResult": "Fail"])
    } else {
      scanResultsToggle.toggle()
      servings = barcodeServings + servings
      TelemetryDeck.signal("Food Item Barcode Scan", parameters: ["barcodeScanResult": "Match"])
    }
  }

  nonisolated func search(barcode: String) async -> [FoodItem] {
    do {
      let sections = try await NetworkRequester.shared.foodSearch(
        upcCode: barcode,
        country: country
      )

      return sections.flatMap({ $0.foods })
    } catch {
      print(error)
    }
    return []
  }
}
