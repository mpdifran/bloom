//
//  FoodScannerControl.swift
//  BloomWidgets
//
//  Created by Mark DiFranco on 2025-10-13.
//

import AppIntents
import SwiftUI
import WidgetKit
import SFSafeSymbols

struct FoodScannerControl: ControlWidget {
  static let kind: String = "com.lotus-labs.bloom.FoodScannerControl"

  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: Self.kind) {
      ControlWidgetButton(action: OpenFoodScannerIntent()) {
        Label("Scan Food", systemSymbol: .barcodeViewfinder)
      }
    }
    .displayName("Food Scanner")
    .description("Open the AI Food Scanner to scan barcodes or analyze food.")
  }
}
