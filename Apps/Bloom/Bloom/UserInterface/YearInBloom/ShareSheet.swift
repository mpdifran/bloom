//
//  ShareSheet.swift
//  Bloom
//
//  Created by Claude on 2025-12-19.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
  let items: [Any]
  var onCompletion: ((Bool) -> Void)?

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.completionWithItemsHandler = { _, completed, _, _ in
      onCompletion?(completed)
    }
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
