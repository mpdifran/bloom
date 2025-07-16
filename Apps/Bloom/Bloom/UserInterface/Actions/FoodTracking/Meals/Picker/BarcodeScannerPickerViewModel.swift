//
//  BarcodeScannerPickerViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-11.
//

import SwiftUI
import BloomModel
import TelemetryDeck

extension BarcodeScannerPickerView {
  @Observable @MainActor
  final class ViewModel {
    var foodItems = [FoodItem]()
    var unknownBarcodes = [String]()
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

extension BarcodeScannerPickerView.ViewModel {

  func added(foodItem: FoodItem, for barcode: String) {
    unknownBarcodes.removeAll(where: { $0 == barcode })

    foodItems.append(foodItem)
  }
}

private extension BarcodeScannerPickerView.ViewModel {

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

    let items = await search(barcode: barcode)

    if items.isEmpty {
      scanResultsErrorToggle.toggle()
      unknownBarcodes.append(barcode)
      TelemetryDeck.signal("Food Item Barcode Scan", parameters: ["barcodeScanResult": "Fail"])
    } else {
      scanResultsToggle.toggle()
      foodItems.append(contentsOf: items)
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
