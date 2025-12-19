//
//  WorkoutBubblesView.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import UIKit
import CoreHealth

// MARK: - Physics Constants

enum PhysicsConstants {
  static let minRadius: CGFloat = 24
  static let maxRadius: CGFloat = 60
  static let gravityMagnitude: CGFloat = 0.5
  static let elasticity: CGFloat = 0.5
  static let resistance: CGFloat = 0.5
  static let friction: CGFloat = 0.2
}

// MARK: - UIViewRepresentable

struct WorkoutBubblesView: UIViewRepresentable {
  let workoutTypes: [WorkoutTypeStats]
  let onBubbleTap: (WorkoutTypeStats) -> Void

  func makeUIView(context: Context) -> PhysicsContainerView {
    let view = PhysicsContainerView()
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: PhysicsContainerView, context: Context) {
    uiView.onBubbleTap = onBubbleTap

    // Setup physics after layout
    DispatchQueue.main.async {
      uiView.setup(workoutTypes: workoutTypes)
    }
  }

  static func dismantleUIView(_ uiView: PhysicsContainerView, coordinator: ()) {
    uiView.reset()
  }
}
