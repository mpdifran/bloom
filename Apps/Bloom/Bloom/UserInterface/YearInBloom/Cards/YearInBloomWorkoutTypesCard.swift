//
//  YearInBloomWorkoutTypesCard.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import UIKit
import CoreHealth
import BloomUI
import SFSafeSymbols
import HealthKit

// MARK: - Physics Constants

enum PhysicsConstants {
  static let minRadius: CGFloat = 24
  static let maxRadius: CGFloat = 60
  static let gravityMagnitude: CGFloat = 0.5
  static let elasticity: CGFloat = 0.5
  static let resistance: CGFloat = 0.5
  static let friction: CGFloat = 0.2
}

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
    // Make circular
    layer.cornerRadius = radius
    clipsToBounds = false

    // Green gradient background
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = bounds
    gradientLayer.cornerRadius = radius
    gradientLayer.colors = [
      UIColor.systemGreen.cgColor,
      UIColor.systemGreen.withAlphaComponent(0.8).cgColor
    ]
    gradientLayer.startPoint = CGPoint(x: 0, y: 0)
    gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    layer.insertSublayer(gradientLayer, at: 0)

    // Shadow
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.2
    layer.shadowOffset = CGSize(width: 0, height: 2)
    layer.shadowRadius = 4

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

    // Calculate max percentage for sizing
    let maxPercentage = workoutTypes.map(\.percentage).max() ?? 1.0

    // Calculate how many bubbles can fill the space
    let averageRadius = (PhysicsConstants.minRadius + PhysicsConstants.maxRadius) / 2
    let estimatedArea = bounds.width * bounds.height
    let bubbleArea = .pi * averageRadius * averageRadius
    let targetBubbleCount = max(workoutTypes.count, Int(estimatedArea / bubbleArea * 1.2))

    // Create extended workout types array by repeating
    var extendedWorkoutTypes: [WorkoutTypeStats] = []
    while extendedWorkoutTypes.count < targetBubbleCount {
      extendedWorkoutTypes.append(contentsOf: workoutTypes)
    }
    extendedWorkoutTypes = Array(extendedWorkoutTypes.prefix(targetBubbleCount)).shuffled()

    // Create bubble views positioned above the visible area
    for stats in extendedWorkoutTypes {
      let radius = calculateRadius(percentage: stats.percentage, maxPercentage: maxPercentage)
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

  private func calculateRadius(percentage: Double, maxPercentage: Double) -> CGFloat {
    let normalizedPercentage = percentage / max(maxPercentage, 0.01)
    return PhysicsConstants.minRadius +
           CGFloat(normalizedPercentage) * (PhysicsConstants.maxRadius - PhysicsConstants.minRadius)
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

// MARK: - Main Card View

struct YearInBloomWorkoutTypesCard: View {
  let stats: YearInBloomWorkoutStats

  @State private var selectedWorkoutStats: WorkoutTypeStats?

  var body: some View {
    YearInBloomCard(
      title: "Workouts",
      focusStat: formattedTotalMinutes,
      focusStatLabel: "Total Minutes",
      includePadding: false,
      includeDivider: false,
      backgroundFill: .background.secondary
    ) {
      VStack(spacing: 12) {
        WorkoutBubblesView(
          workoutTypes: stats.topWorkoutTypes,
          onBubbleTap: { tappedStats in
            withAnimation(.bouncy) {
              if selectedWorkoutStats == tappedStats {
                selectedWorkoutStats = nil
              } else {
                selectedWorkoutStats = tappedStats
              }
            }
          }
        )
        .frame(height: 220)
        .padding(.horizontal)

        WorkoutDetailCard(
          selectedWorkoutStats: selectedWorkoutStats,
          yearTotals: stats.yearTotals,
          totalDistance: stats.totalDistanceMeters
        )
        .padding(.horizontal)
        .padding(.bottom)
        .animation(.bouncy, value: selectedWorkoutStats)
      }
    }
    .sensoryFeedback(.selection, trigger: selectedWorkoutStats)
  }

  private var formattedTotalMinutes: String {
    let minutes = Int(stats.yearTotals.totalDurationMinutes)
    return minutes.formatted()
  }
}

// MARK: - Detail Card

private struct WorkoutDetailCard: View {
  let selectedWorkoutStats: WorkoutTypeStats?
  let yearTotals: YearTotals
  let totalDistance: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        if let selected = selectedWorkoutStats {
          Image(systemName: selected.activityType.systemImage)
            .font(.title2)
          Text(selected.activityName)
            .font(.headline)
            .fontDesign(.rounded)
        } else {
          Image(systemName: "figure.run.circle.fill")
            .font(.title2)
          Text("All Workouts")
            .font(.headline)
            .fontDesign(.rounded)
        }
        Spacer()
      }

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        statCard(label: "Duration", value: formattedDuration, symbol: .clockFill)
        statCard(label: "Workouts", value: formattedWorkoutCount, symbol: .flameFill)
        statCard(label: "Calories", value: formattedCalories, symbol: .boltFill)

        if distanceValue > 0 {
          statCard(label: "Distance", value: formattedDistance, symbol: .locationFill)
        }

        if let zoneMinutes = zoneMinutesValue, zoneMinutes > 0 {
          statCard(label: "Zone Min", value: "\(Int(zoneMinutes))", symbol: .heartFill)
        }
      }
    }
    .padding(12)
    .background(.background, in: RoundedRectangle(cornerRadius: 14))
  }

  private func statCard(label: String, value: String, symbol: SFSymbol) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Label(label, systemSymbol: symbol)
        .font(.caption)
        .foregroundStyle(.secondary)

      Spacer()

      Text(value)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(minHeight: 50)
    .padding(10)
    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
  }

  // MARK: - Computed Values

  private var durationMinutes: Double {
    selectedWorkoutStats?.totalDurationMinutes ?? yearTotals.totalDurationMinutes
  }

  private var formattedDuration: String {
    let hours = Int(durationMinutes / 60)
    let minutes = Int(durationMinutes.truncatingRemainder(dividingBy: 60))
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
  }

  private var formattedWorkoutCount: String {
    let count = selectedWorkoutStats?.count ?? yearTotals.totalWorkouts
    return "\(count)"
  }

  private var formattedCalories: String {
    let calories = selectedWorkoutStats?.totalCaloriesBurned ?? yearTotals.totalCaloriesBurned
    return Int(calories).formatted()
  }

  private var distanceValue: Double {
    selectedWorkoutStats?.totalDistanceMeters ?? totalDistance
  }

  private var formattedDistance: String {
    let km = distanceValue / 1000
    if km >= 100 {
      return "\(Int(km)) km"
    }
    return String(format: "%.1f km", km)
  }

  private var zoneMinutesValue: Double? {
    if let selected = selectedWorkoutStats {
      return selected.zoneMinutes?.scaledZoneMinutes
    }
    return yearTotals.totalZoneMinutes?.scaledZoneMinutes
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      YearInBloomWorkoutTypesCard(stats: .preview)
    }
  }
}
