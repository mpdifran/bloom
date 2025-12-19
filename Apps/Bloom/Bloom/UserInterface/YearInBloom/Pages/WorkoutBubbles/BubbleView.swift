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

    // Icon
    let config = UIImage.SymbolConfiguration(pointSize: radius * 0.6, weight: .semibold)
    let image = UIImage(systemName: workoutStats.activityType.systemImage, withConfiguration: config)
    iconImageView.image = image
    iconImageView.tintColor = .black
    iconImageView.contentMode = .center
    iconImageView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(iconImageView)

    NSLayoutConstraint.activate([
      iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
      iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
      iconImageView.widthAnchor.constraint(equalToConstant: radius),
      iconImageView.heightAnchor.constraint(equalToConstant: radius)
    ])

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
