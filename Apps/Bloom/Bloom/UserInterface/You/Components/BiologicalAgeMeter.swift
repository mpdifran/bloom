//
//  BiologicalAgeMeter.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-15.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols

extension BiologicalAgeMeter {
  enum CenterContentKind {
    case bioAge
    case profileImage
  }
}

struct BiologicalAgeMeter: View {
  let chronologicalAge: Int
  let biologicalAge: Double?
  let centerContentKind: CenterContentKind

  // Arc configuration
  private let startAngle = 0.125 // 7:00 position
  private let endAngle = 0.875   // 5:00 position
  private let centerAngle = 0.5  // 12:00 position (neutral)
  private let maxAgeDifference = 10.0 // Maximum years difference to display

  init(
    chronologicalAge: Int? = nil,
    biologicalAge: Double?,
    centerContentKind: CenterContentKind = .bioAge
  ) {
    self.chronologicalAge = chronologicalAge ?? {
      let birthYear = HealthDefaults.shared.getBirthYear()
      guard birthYear > 0 else { return 0 }
      return Calendar.current.component(.year, from: .now) - birthYear
    }()
    self.biologicalAge = biologicalAge
    self.centerContentKind = centerContentKind
  }

  var body: some View {
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

        ZStack {
          // Muted yellow circle for neutral case
          if abs(ageDifference) < 0.5 {
            Circle()
              .fill(.mutedYellow)
              .frame(width: size * 0.16, height: size * 0.16)
          }

          Circle()
            .fill(.white)
            .frame(width: size * 0.12, height: size * 0.12)
            .shadow(color: .black.opacity(0.2), radius: size * 0.015, x: 0, y: size * 0.01)
        }
        .offset(y: -radius)
        .rotationEffect(indicatorAngle)

        // Center content
        switch centerContentKind {
        case .bioAge:
          VStack(spacing: size * 0.02) {
            Text(bioAgeDescription)
              .font(.system(size: size * 0.22, weight: .heavy, design: .rounded))
              .contentTransition(.numericText(value: biologicalAge ?? 0))

            Text(ageDifferenceText)
              .font(.system(size: size * 0.07, weight: .heavy, design: .rounded))
              .foregroundColor(progressColor)
              .padding(4)
              .padding(.horizontal, 8)
              .background {
                RoundedRectangle(cornerRadius: 8)
                  .fill(.fill)
              }
          }
        case .profileImage:
          UserProfilePhotoView(dimension: size * 0.5)
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .aspectRatio(1, contentMode: .fit)
    .animation(.easeInOut(duration: 1.5), value: biologicalAge)
  }
}

private extension BiologicalAgeMeter {

  var bioAgeDescription: String {
    if let biologicalAge {
      return biologicalAge.format(using: .oneDecimalPlace)
    }
    return "--"
  }

  var ageDifference: Double {
    guard let biologicalAge else { return 0 }
    return biologicalAge - Double(chronologicalAge)
  }

  var ageDifferenceText: String {
    let formatted = ageDifference.format(using: .oneDecimalPlace)
    if ageDifference > 0 {
      return "+\(formatted)"
    }
    return formatted
  }

  private var normalizedPosition: Double {
    // Clamp the difference to max range
    let clampedDifference = max(-maxAgeDifference, min(maxAgeDifference, ageDifference))
    // Normalize to 0...1 range where 0.5 is center
    return 0.5 + (clampedDifference / maxAgeDifference) * 0.375
  }

  private var indicatorAngle: Angle {
    // Convert position to angle (0.125 = -135°, 0.875 = 135°)
    let angleRange = 270.0 // Total arc span in degrees
    let startDegrees = -135.0
    let position = (normalizedPosition - startAngle) / (endAngle - startAngle)
    return .degrees(startDegrees + (position * angleRange))
  }

  private var progressColor: Color {
    if abs(ageDifference) < 0.5 {
      return .clear
    } else if ageDifference < 0 {
      return .mutedGreen
    } else {
      return .mutedPink
    }
  }
}

#Preview {
  @Previewable @State var bioAge: Double? = nil

  let dimension: CGFloat = 200

  PreviewEnvironment {
    BloomScrollView {
      BiologicalAgeMeter(chronologicalAge: 40, biologicalAge: bioAge, centerContentKind: .profileImage)
        .frame(square: dimension)

      BiologicalAgeMeter(chronologicalAge: 45, biologicalAge: bioAge)
        .frame(square: dimension)

      BiologicalAgeMeter(chronologicalAge: 42, biologicalAge: bioAge)
        .frame(square: dimension)

      BiologicalAgeMeter(chronologicalAge: 30, biologicalAge: bioAge)
        .frame(square: dimension)

      BiologicalAgeMeter(chronologicalAge: 60, biologicalAge: bioAge, centerContentKind: .profileImage)
        .frame(square: dimension)

      BiologicalAgeMeter(chronologicalAge: 42, biologicalAge: nil)
        .frame(square: dimension)
    }
  }
  .onAppear {
    bioAge = 42
  }
}
