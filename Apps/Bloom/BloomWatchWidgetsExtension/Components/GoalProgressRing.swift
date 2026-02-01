//
//  GoalProgressRing.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-02-01.
//

import BloomFoundation
import SwiftUI

/// Circular progress ring for goal widgets with SF Symbol icon in center.
struct GoalProgressRing: View {
  let progress: Double
  let systemImage: String
  let tintColor: Color

  private var clampedProgress: Double {
    min(max(progress, 0), 1)
  }

  var body: some View {
    GeometryReader { geometry in
      let size = min(geometry.size.width, geometry.size.height)
      let lineWidth = size * 0.14
      let iconSize = size * 0.4

      ZStack {
        // Background track
        Circle()
          .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)

        // Progress arc
        Circle()
          .trim(from: 0, to: clampedProgress)
          .stroke(tintColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
          .rotationEffect(.degrees(-90))

        // Center icon
        Image(systemName: systemImage)
          .font(.system(size: iconSize, weight: .medium))
          .foregroundStyle(tintColor)
      }
      .frame(width: size, height: size)
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .aspectRatio(1, contentMode: .fit)
  }
}

#Preview("50%") {
  GoalProgressRing(
    progress: 0.5,
    systemImage: "figure.walk",
    tintColor: .green
  )
  .frame(width: 80, height: 80)
}

#Preview("100%") {
  GoalProgressRing(
    progress: 1.0,
    systemImage: "flame.fill",
    tintColor: .orange
  )
  .frame(width: 80, height: 80)
}

#Preview("75%") {
  GoalProgressRing(
    progress: 0.75,
    systemImage: "drop.fill",
    tintColor: .blue
  )
  .frame(width: 80, height: 80)
}
