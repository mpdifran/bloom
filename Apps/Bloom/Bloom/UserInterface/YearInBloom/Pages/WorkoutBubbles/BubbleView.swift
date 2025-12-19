//
//  BubbleView.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import UIKit
import CoreHealth

// MARK: - Bubble UIView

final class BubbleView: UIView {
  let workoutStats: WorkoutTypeStats
  let radius: CGFloat
  var onTap: (() -> Void)?

  private let iconImageView = UIImageView()

  init(workoutStats: WorkoutTypeStats, radius: CGFloat) {
    self.workoutStats = workoutStats
    self.radius = radius
    super.init(frame: CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2))
    setupView()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    // Make circular with green background
    layer.cornerRadius = radius
    backgroundColor = .systemGreen

    // Icon - SF Symbols must use .center contentMode
    let config = UIImage.SymbolConfiguration(pointSize: radius * 0.6, weight: .semibold)
    let image = UIImage(systemName: workoutStats.activityType.systemImage, withConfiguration: config)
    iconImageView.image = image
    iconImageView.tintColor = .black
    iconImageView.contentMode = .center
    iconImageView.frame = bounds  // Set frame directly - Auto Layout doesn't resolve in time for snapshot
    addSubview(iconImageView)

    // Tap gesture
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    addGestureRecognizer(tap)
    isUserInteractionEnabled = true
  }

  @objc private func handleTap() {
    onTap?()
  }

  override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
    .ellipse
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BubbleViewPreview(
        workoutStats: WorkoutTypeStats(
          activityTypeRawValue: 37,
          activityName: "Running",
          count: 50,
          totalDurationMinutes: 1500,
          totalCaloriesBurned: 15000,
          percentage: 0.4
        ),
        radius: 50
      )
      .frame(width: 100, height: 100)

      BubbleViewPreview(
        workoutStats: WorkoutTypeStats(
          activityTypeRawValue: 37,
          activityName: "Running",
          count: 50,
          totalDurationMinutes: 1500,
          totalCaloriesBurned: 15000,
          percentage: 0.4
        ),
        radius: 25
      )
      .frame(width: 50, height: 50)

      BubbleViewPreview(
        workoutStats: WorkoutTypeStats(
          activityTypeRawValue: 37,
          activityName: "Running",
          count: 50,
          totalDurationMinutes: 1500,
          totalCaloriesBurned: 15000,
          percentage: 0.4
        ),
        radius: 10
      )
      .frame(width: 20, height: 20)
    }
  }
}

private struct BubbleViewPreview: UIViewRepresentable {
  let workoutStats: WorkoutTypeStats
  let radius: CGFloat

  func makeUIView(context: Context) -> BubbleView {
    BubbleView(workoutStats: workoutStats, radius: radius)
  }

  func updateUIView(_ uiView: BubbleView, context: Context) {}
}
