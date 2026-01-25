//
//  BiologicalAgeMeter.swift
//  BloomUI
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import BloomFoundation

/// A circular gauge that displays biological age relative to chronological age.
/// Shows the bio age value in the center with a badge indicating the difference.
public struct BiologicalAgeMeter: View {
  let chronologicalAge: Double
  let biologicalAge: Double?

  // Arc configuration
  private let startAngle = 0.125 // 7:00 position
  private let endAngle = 0.875   // 5:00 position
  private let centerAngle = 0.5  // 12:00 position (neutral)
  private let maxAgeDifference = 10.0 // Maximum years difference to display

  public init(
    chronologicalAge: Double,
    biologicalAge: Double?
  ) {
    self.chronologicalAge = chronologicalAge
    self.biologicalAge = biologicalAge
  }

  public var body: some View {
    GeometryReader { geometry in
      let size = min(geometry.size.width, geometry.size.height)
      let radius = size * 0.4

      ZStack {
        // Background arc track
        Circle()
          .trim(from: startAngle, to: endAngle)
          .stroke(.fill, style: StrokeStyle(lineWidth: size * 0.16, lineCap: .round))
          .rotationEffect(.degrees(90))
          .frame(width: radius * 2, height: radius * 2)

        // Progress arc (from center to current position)
        Circle()
          .trim(
            from: ageDifference < 0 ? normalizedPosition : centerAngle,
            to: ageDifference < 0 ? centerAngle : normalizedPosition
          )
          .stroke(progressColor, style: StrokeStyle(lineWidth: size * 0.16, lineCap: .round))
          .rotationEffect(.degrees(90))
          .frame(width: radius * 2, height: radius * 2)
          .shadow(color: progressColor.opacity(0.3), radius: size * 0.02, x: 0, y: size * 0.01)

        // Indicator dot
        Circle()
          .fill(.white)
          .frame(width: size * 0.12, height: size * 0.12)
          .shadow(color: .black.opacity(0.2), radius: size * 0.015, x: 0, y: size * 0.01)
          .offset(y: -radius)
          .rotationEffect(indicatorAngle)

        // Center content - bio age value and badge
        VStack(spacing: size * 0.02) {
          Text(bioAgeDescription)
            .font(.system(size: size * 0.22, weight: .heavy, design: .rounded))
            .contentTransition(.numericText(value: biologicalAge ?? 0))

          ageDifferenceBadge(size: size)
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .aspectRatio(1, contentMode: .fit)
    .animation(.easeInOut(duration: 1.5), value: biologicalAge)
  }
}

// MARK: - Private Helpers

private extension BiologicalAgeMeter {

  func ageDifferenceBadge(size: CGFloat) -> some View {
    Text(ageDifferenceText)
      .font(.system(size: size * 0.07, weight: .black, design: .rounded))
      .foregroundColor(.white)
      .contentTransition(.numericText(value: ageDifference))
      .padding(size * 0.02)
      .padding(.horizontal, size * 0.04)
      .background {
        Capsule()
          .fill(ageDifferenceBackgroundColor)
      }
  }

  var bioAgeDescription: String {
    if let biologicalAge {
      return biologicalAge.format(using: .oneDecimalPlace)
    }
    return "--"
  }

  var ageDifference: Double {
    guard let biologicalAge else { return 0 }
    return biologicalAge - chronologicalAge
  }

  var ageDifferenceText: String {
    let formatted = ageDifference.format(using: .oneDecimalPlace)
    if ageDifference > 0 {
      return "+\(formatted)"
    }
    return formatted
  }

  var normalizedPosition: Double {
    // Clamp the difference to max range
    let clampedDifference = max(-maxAgeDifference, min(maxAgeDifference, ageDifference))
    // Normalize to 0...1 range where 0.5 is center
    return 0.5 + (clampedDifference / maxAgeDifference) * 0.375
  }

  var indicatorAngle: Angle {
    // Convert position to angle (0.125 = -135°, 0.875 = 135°)
    let angleRange = 270.0 // Total arc span in degrees
    let startDegrees = -135.0
    let position = (normalizedPosition - startAngle) / (endAngle - startAngle)
    return .degrees(startDegrees + (position * angleRange))
  }

  var progressColor: Color {
    ageDifference <= 0 ? .mutedGreen : .mutedPink
  }

  var ageDifferenceBackgroundColor: Color {
    ageDifference <= 0 ? .mutedGreen : .mutedPink
  }
}

#Preview {
  VStack(spacing: 20) {
    BiologicalAgeMeter(chronologicalAge: 40.0, biologicalAge: 35.0)
      .frame(width: 150, height: 150)

    BiologicalAgeMeter(chronologicalAge: 40.0, biologicalAge: 45.0)
      .frame(width: 150, height: 150)

    BiologicalAgeMeter(chronologicalAge: 40.0, biologicalAge: nil)
      .frame(width: 150, height: 150)
  }
  .padding()
}
