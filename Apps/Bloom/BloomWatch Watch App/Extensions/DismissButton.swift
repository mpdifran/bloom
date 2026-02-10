//
//  DismissButton.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-02-10.
//

import SwiftUI

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
      Image(systemName: "xmark")
    }
  }
}
