//
//  RootViewModalPresentationManager.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-08.
//

import SwiftUI
import BloomModel

extension RootViewModalPresentationManager {
  enum SheetKind {
    case privacyUnknownSheet([ConsentManager.ConsentType])
    case sale(SaleDetails)
  }
}

/// Manages sheets that are presented on app foreground. Uses a priority system to determine the one sheet to show, or nil if no sheet should be shown.
@MainActor
final class RootViewModalPresentationManager {
  static let shared = RootViewModalPresentationManager()

  private init() { }
}

extension RootViewModalPresentationManager {

  /// Determines which sheet to present, or `nil` if no sheet should be shown.
  func determineSheetToPresent() async -> SheetKind? {
    let missingConsentStates = await ConsentManager.shared.missingConsentStates()

    if missingConsentStates.isNotEmpty {
      return .privacyUnknownSheet(missingConsentStates)
    }
//    if let sale = await SalesManager.shared.shouldShowSale() {
//      return .sale(sale)
//    }

    return nil
  }
}
