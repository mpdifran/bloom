//
//  BarcodeScannerViewModel.swift
//  Bloom
//
//  Created by Claude on 2025-10-22.
//

import SwiftUI
import BloomModel
import TelemetryDeck
import CoreNetwork

extension BarcodeScannerView {
  @Observable @MainActor
  final class ViewModel {

    enum BarcodeState: Identifiable {
      case loading(String)
      case found(String, [FoodItem])
      case notFound(String)

      var id: String {
        switch self {
        case .loading(let barcode), .found(let barcode, _), .notFound(let barcode):
          return barcode
        }
      }

      var barcode: String {
        switch self {
        case .loading(let barcode), .found(let barcode, _), .notFound(let barcode):
          return barcode
        }
      }
    }

    var barcodeStates = [BarcodeState]()
    var country: String = "usa"

    var scanResultsToggle = false
    var scanResultsErrorToggle = false

    let cameraManager = CameraManager()

    init() {
      setupObservers()
    }

    private var detectedBarcodes = Set<String>()
  }
}

extension BarcodeScannerView.ViewModel {

  func added(foodItem: FoodItem, for barcode: String) {
    // Remove the notFound state
    barcodeStates.removeAll(where: { $0.barcode == barcode })

    // Add as found with the new food item
    barcodeStates.insert(.found(barcode, [foodItem]), at: 0)
  }
}

private extension BarcodeScannerView.ViewModel {

  func setupObservers() {
    cameraManager.onNewBarcode = { [weak self] barcode in
      Task {
        await self?.handleNewBarcode(barcode)
      }
    }
  }

  func handleNewBarcode(_ barcode: String) async {
    guard !detectedBarcodes.contains(barcode) else { return }

    detectedBarcodes.insert(barcode)

    // Add loading state immediately
    barcodeStates.insert(.loading(barcode), at: 0)

    // Search for the barcode
    let foodItems = await search(barcode: barcode)

    // Update state based on results
    if let index = barcodeStates.firstIndex(where: { $0.barcode == barcode }) {
      barcodeStates.remove(at: index)

      if foodItems.isEmpty {
        scanResultsErrorToggle.toggle()
        barcodeStates.insert(.notFound(barcode), at: 0)
        TelemetryDeck.signal("Food Item Barcode Scan", parameters: ["barcodeScanResult": "Fail"])
      } else {
        scanResultsToggle.toggle()
        barcodeStates.insert(.found(barcode, foodItems), at: 0)
        TelemetryDeck.signal("Food Item Barcode Scan", parameters: ["barcodeScanResult": "Match"])
      }
    }
  }

  nonisolated func search(barcode: String) async -> [FoodItem] {
    do {
      let sections = try await NetworkRequester.shared.foodSearch(
        upcCode: barcode,
        country: country
      )

      let foodItems = sections.flatMap({ $0.foods })

      // Upsert food items in the background
      Task.detached {
        await FoodItemUpsertProcessor.shared.upsertFoodItems(foodItems)
      }

      return foodItems
    } catch {
      print(error)
    }
    return []
  }
}
