//
//  PhysicsContainerView.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import UIKit
import CoreHealth

// MARK: - Physics Container UIView

final class PhysicsContainerView: UIView {
  private var animator: UIDynamicAnimator?
  private var gravity: UIGravityBehavior?
  private var collision: UICollisionBehavior?
  private var itemBehavior: UIDynamicItemBehavior?
  private var bubbleViews: [BubbleView] = []
  private var pendingBubbles: [BubbleView] = []
  private var dropTimer: Timer?
  private var isSetup = false

  var onBubbleTap: ((WorkoutTypeStats) -> Void)?

  func setup(workoutTypes: [WorkoutTypeStats]) {
    guard !isSetup, bounds.width > 0, bounds.height > 0 else { return }
    isSetup = true

    // Clean up any existing setup
    animator?.removeAllBehaviors()
    dropTimer?.invalidate()
    dropTimer = nil
    bubbleViews.forEach { $0.removeFromSuperview() }
    bubbleViews.removeAll()
    pendingBubbles.removeAll()

    // Create animator
    let newAnimator = UIDynamicAnimator(referenceView: self)
    animator = newAnimator

    // Downward gravity
    let gravityBehavior = UIGravityBehavior()
    gravityBehavior.gravityDirection = CGVector(dx: 0, dy: PhysicsConstants.gravityMagnitude)
    newAnimator.addBehavior(gravityBehavior)
    gravity = gravityBehavior

    // Collision with bounds (except top) + between items
    let collisionBehavior = UICollisionBehavior()
    collisionBehavior.collisionMode = .everything
    // Add left, bottom, and right boundaries (no top boundary)
    collisionBehavior.addBoundary(
      withIdentifier: "left" as NSCopying,
      from: CGPoint(x: 0, y: 0),
      to: CGPoint(x: 0, y: bounds.height)
    )
    collisionBehavior.addBoundary(
      withIdentifier: "bottom" as NSCopying,
      from: CGPoint(x: 0, y: bounds.height),
      to: CGPoint(x: bounds.width, y: bounds.height)
    )
    collisionBehavior.addBoundary(
      withIdentifier: "right" as NSCopying,
      from: CGPoint(x: bounds.width, y: bounds.height),
      to: CGPoint(x: bounds.width, y: 0)
    )
    newAnimator.addBehavior(collisionBehavior)
    collision = collisionBehavior

    // Item properties
    let itemBehaviorInstance = UIDynamicItemBehavior()
    itemBehaviorInstance.elasticity = PhysicsConstants.elasticity
    itemBehaviorInstance.resistance = PhysicsConstants.resistance
    itemBehaviorInstance.friction = PhysicsConstants.friction
    itemBehaviorInstance.allowsRotation = false
    newAnimator.addBehavior(itemBehaviorInstance)
    itemBehavior = itemBehaviorInstance

    // Calculate max average duration for sizing
    let maxAvgDuration = workoutTypes.map { $0.totalDurationMinutes / Double($0.count) }.max() ?? 1.0

    // Calculate how many bubbles can fill the space
    let averageRadius = (PhysicsConstants.minRadius + PhysicsConstants.maxRadius) / 2
    let estimatedArea = bounds.width * bounds.height
    let bubbleArea = .pi * averageRadius * averageRadius
    let targetBubbleCount = max(workoutTypes.count, Int(estimatedArea / bubbleArea * 2.5))

    // Create extended workout types array by repeating
    var extendedWorkoutTypes: [WorkoutTypeStats] = []
    while extendedWorkoutTypes.count < targetBubbleCount {
      extendedWorkoutTypes.append(contentsOf: workoutTypes)
    }
    extendedWorkoutTypes = Array(extendedWorkoutTypes.prefix(targetBubbleCount)).shuffled()

    // Create bubble views positioned above the visible area
    for stats in extendedWorkoutTypes {
      let avgDuration = stats.totalDurationMinutes / Double(stats.count)
      let radius = calculateRadius(value: avgDuration, maxValue: maxAvgDuration)
      let bubble = BubbleView(workoutStats: stats, radius: radius)

      // Position above the visible area with random X
      let minX = radius
      let maxX = max(radius, bounds.width - radius)
      let x = CGFloat.random(in: minX...maxX)
      let y = -radius - CGFloat.random(in: 0...100)
      bubble.center = CGPoint(x: x, y: y)

      bubble.onTap = { [weak self] in
        self?.onBubbleTap?(stats)
      }

      pendingBubbles.append(bubble)
    }

    // Start dropping bubbles
    startDroppingBubbles()
  }

  private func startDroppingBubbles() {
    let bubblesPerDrop = 3
    let dropInterval: TimeInterval = 0.15

    dropTimer = Timer.scheduledTimer(withTimeInterval: dropInterval, repeats: true) { [weak self] timer in
      guard let self else {
        timer.invalidate()
        return
      }

      guard !pendingBubbles.isEmpty else {
        timer.invalidate()
        dropTimer = nil
        return
      }

      // Drop a few bubbles
      let countToDrop = min(bubblesPerDrop, pendingBubbles.count)
      for _ in 0..<countToDrop {
        guard !pendingBubbles.isEmpty else { break }
        let bubble = pendingBubbles.removeFirst()

        addSubview(bubble)
        gravity?.addItem(bubble)
        collision?.addItem(bubble)
        itemBehavior?.addItem(bubble)
        bubbleViews.append(bubble)
      }
    }
  }

  private func calculateRadius(value: Double, maxValue: Double) -> CGFloat {
    let normalized = value / max(maxValue, 0.01)
    return PhysicsConstants.minRadius +
           CGFloat(normalized) * (PhysicsConstants.maxRadius - PhysicsConstants.minRadius)
  }

  func reset() {
    isSetup = false
    dropTimer?.invalidate()
    dropTimer = nil
    animator?.removeAllBehaviors()
    animator = nil
    gravity = nil
    collision = nil
    itemBehavior = nil
    bubbleViews.forEach { $0.removeFromSuperview() }
    bubbleViews.removeAll()
    pendingBubbles.removeAll()
  }
}
