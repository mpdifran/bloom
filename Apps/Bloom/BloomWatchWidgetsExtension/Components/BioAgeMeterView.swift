//
//  BioAgeMeterView.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-01-31.
//

import BloomFoundation
import SwiftUI
import WidgetKit

/// Widget version of BiologicalAgeMeter, matching the app's design.
/// Arc spans from 7:00 to 5:00 position with neutral at 12:00.
struct BioAgeMeterView: View {
  let entry: BiologicalAgeEntry
  let showCenterText: Bool

  // Arc configuration - matches BiologicalAgeMeter in BloomUI
  private let startAngle = 0.125  // 7:00 position
  private let endAngle = 0.875    // 5:00 position
  private let centerAngle = 0.5   // 12:00 position (neutral)
  private let maxAgeDifference = 10.0

  init(entry: BiologicalAgeEntry, showCenterText: Bool = true) {
    self.entry = entry
    self.showCenterText = showCenterText
  }

  var body: some View {
    GeometryReader { geometry in
      let size = min(geometry.size.width, geometry.size.height)
      let radius = size * 0.4
      let lineWidth = size * 0.14

      ZStack {
        // Background arc track
        Circle()
          .trim(from: startAngle, to: endAngle)
          .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
          .rotationEffect(.degrees(90))
          .frame(width: radius * 2, height: radius * 2)

        // Progress arc (from center to current position)
        if entry.ageDelta != nil {
          Circle()
            .trim(
              from: ageDifference < 0 ? normalizedPosition : centerAngle,
              to: ageDifference < 0 ? centerAngle : normalizedPosition
            )
            .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .widgetAccentable()
            .rotationEffect(.degrees(90))
            .frame(width: radius * 2, height: radius * 2)
        }

        // Indicator dot
        Circle()
          .fill(.white)
//          .widgetAccentable()
          .frame(width: size * 0.1, height: size * 0.1)
          .offset(y: -radius)
          .rotationEffect(indicatorAngle)

        // Center content - bio age value (optional)
        if showCenterText {
          if let bioAge = entry.biologicalAge {
            Text(bioAge.format(using: .oneDecimalPlace))
              .font(.system(size: size * 0.25, weight: .heavy, design: .rounded))
          } else {
            Text("--")
              .font(.system(size: size * 0.25, weight: .heavy, design: .rounded))
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .aspectRatio(1, contentMode: .fit)
  }

  private var ageDifference: Double {
    entry.ageDelta ?? 0
  }

  private var normalizedPosition: Double {
    let clampedDifference = max(-maxAgeDifference, min(maxAgeDifference, ageDifference))
    return 0.5 + (clampedDifference / maxAgeDifference) * 0.375
  }

  private var indicatorAngle: Angle {
    let angleRange = 270.0
    let startDegrees = -135.0
    let position = (normalizedPosition - startAngle) / (endAngle - startAngle)
    return .degrees(startDegrees + (position * angleRange))
  }

  private var progressColor: Color {
    ageDifference <= 0 ? .mutedGreen : .mutedPink
  }
}
