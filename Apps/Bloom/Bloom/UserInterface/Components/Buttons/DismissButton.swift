//
//  DismissButton.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-19.
//

import SwiftUI
import SFSafeSymbols

struct DismissButton: View {
  let performDismiss: (() -> Void)?

  init(performDismiss: (() -> Void)? = nil) {
    self.performDismiss = performDismiss
  }

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Button {
      if let performDismiss {
        performDismiss()
      } else {
        dismiss()
      }
    } label: {
      Image(systemSymbol: .xmark)
        .bold()
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  PreviewSheetPresent {
    NavigationStack {
      List {
        Text("1")
        Text("2")
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
  }
}
