//
//  OpenFoodScannerIntent.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-13.
//

import AppIntents
import Foundation

struct OpenFoodScannerIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Food Scanner"
  static let description = IntentDescription("Opens the AI Food Scanner to scan barcodes or analyze food.")
  static let openAppWhenRun: Bool = true

  func perform() async throws -> some IntentResult & OpensIntent {
    let url = URL(string: "https://api.trybloom.app/action/food-scanner")!
    return .result(opensIntent: OpenURLIntent(url))
  }
}
