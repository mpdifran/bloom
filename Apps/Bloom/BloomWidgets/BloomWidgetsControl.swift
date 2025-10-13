//
//  BloomWidgetsControl.swift
//  BloomWidgets
//
//  Created by Mark DiFranco on 2025-10-12.
//

import AppIntents
import SwiftUI
import WidgetKit

struct BloomWidgetsControl: ControlWidget {
  static let kind: String = "com.lotus-labs.bloom.FoodScannerControl"

  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: Self.kind) {
      ControlWidgetButton(action: OpenFoodScannerIntent()) {
        Label("Scan Food", systemImage: "barcode.viewfinder")
      }
    }
    .displayName("Food Scanner")
    .description("Open the AI Food Scanner to scan barcodes or analyze food.")
  }
}
