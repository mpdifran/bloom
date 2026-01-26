//
//  View+RemoveCancellation.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-26.
//

import SwiftUI

extension View {

  func removeCancellationToolbarItem() -> some View {
    toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("", action: {}).opacity(0.0).disabled(true)
      }
    }
  }
}
