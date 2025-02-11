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
    var mode: Mode = .base
    var image: UIImage?
    var scannedFoodName: String?
    var servings = [FoodItemServing]()
    var suggestedServings = [FoodItemServing]()
    var scanResultsToggle = false
    var country: FoodCountry = .usa
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
    guard let smallerImage = image.resized(toWidth: 1200) else {
      await MainActor.run { mode = .base }
      return
    }

    do {
      let response = try await NetworkRequester.shared.foodAIEstimate(image: smallerImage)
      let servings = response.servings.map { $0.asServing() }
      let suggestedServings = response.suggestedServings.map { $0.asServing() }

      await MainActor.run {
        self.scannedFoodName = response.name
        self.servings = servings
        self.suggestedServings = suggestedServings

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
    let servings = foodItems.map { FoodItemServing(serving: 1, foodItem: $0) }

    if servings.isEmpty {
      self.servings.append(contentsOf: servings)
    } else {
      self.suggestedServings = self.servings
      self.servings.append(contentsOf: servings)
    }

    if servings.isNotEmpty {
      scanResultsToggle.toggle()
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
