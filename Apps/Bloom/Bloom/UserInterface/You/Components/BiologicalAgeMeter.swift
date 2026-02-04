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
  let chronologicalAge: Double
  let biologicalAge: Double?
  let centerContentKind: CenterContentKind

  // Arc configuration
  private let startAngle = 0.125 // 7:00 position
  private let endAngle = 0.875   // 5:00 position
  private let centerAngle = 0.5  // 12:00 position (neutral)
  private let maxAgeDifference = 10.0 // Maximum years difference to display

  init(
    chronologicalAge: Double? = nil,
    biologicalAge: Double?,
    centerContentKind: CenterContentKind = .bioAge
  ) {
    self.chronologicalAge = chronologicalAge ?? Self.computeChronologicalAge()
    self.biologicalAge = biologicalAge
    self.centerContentKind = centerContentKind
  }

  private static func computeChronologicalAge() -> Double {
    let birthYear = HealthDefaults.shared.getBirthYear()
    guard birthYear > 0 else { return 0 }

    let birthMonth = HealthDefaults.shared.getBirthMonth()
    let calendar = Calendar.current
    let now = Date.now
    let currentYear = calendar.component(.year, from: now)
    let currentMonth = calendar.component(.month, from: now)
    let currentDay = calendar.component(.day, from: now)

    var years = Double(currentYear - birthYear)

    if birthMonth > 0 {
      let monthsSinceBirthday: Int
      if currentMonth > birthMonth || (currentMonth == birthMonth && currentDay >= 15) {
        monthsSinceBirthday = currentMonth - birthMonth + (currentDay >= 15 ? 0 : -1)
      } else {
        years -= 1
        monthsSinceBirthday = 12 - birthMonth + currentMonth + (currentDay >= 15 ? 0 : -1)
      }
      return years + (Double(max(0, monthsSinceBirthday)) / 12.0)
    } else {
      let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
      let daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
      return years + (Double(dayOfYear - 1) / Double(daysInYear))
    }
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

        Circle()
          .fill(.white)
          .frame(width: size * 0.12, height: size * 0.12)
          .shadow(color: .black.opacity(0.2), radius: size * 0.015, x: 0, y: size * 0.01)
        .offset(y: -radius)
        .rotationEffect(indicatorAngle)

        // Center content
        switch centerContentKind {
        case .bioAge:
          VStack(spacing: size * 0.02) {
            Text(bioAgeDescription)
              .font(.system(size: size * 0.22, weight: .heavy, design: .rounded))
              .contentTransition(.numericText(value: biologicalAge ?? 0))

            ageDifferenceBadge(size: size)
          }
        case .profileImage:
          UserProfilePhotoView(dimension: size * 0.5)
            .overlay {
              ageDifferenceBadge(size: size)
                .zStackAlignment(.bottom)
                .offset(y: size * 0.05)
            }
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .aspectRatio(1, contentMode: .fit)
    .animation(.easeInOut(duration: 1.5), value: biologicalAge)
  }
}

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
    // Round to 1 decimal place to check for zero
    let rounded = (ageDifference * 10).rounded() / 10
    if rounded == 0 {
      return "0"
    }
    let formatted = ageDifference.format(using: .oneDecimalPlace)
    if rounded > 0 {
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
    ageDifference <= 0 ? .mutedGreen : .mutedPink
  }

  private var ageDifferenceBackgroundColor: Color {
    ageDifference <= 0 ? .mutedGreen : .mutedPink
  }
}

#Preview {
  @Previewable @State var bioAge: Double? = nil

  let dimension: CGFloat = 200

  PreviewEnvironment {
    BloomScrollView {
      BiologicalAgeMeter(chronologicalAge: 40.0, biologicalAge: bioAge, centerContentKind: .profileImage)
        .frame(square: dimension)

      BiologicalAgeMeter(chronologicalAge: 45.0, biologicalAge: bioAge)
        .frame(square: dimension)

      BiologicalAgeMeter(chronologicalAge: 42.0, biologicalAge: bioAge)
        .frame(square: dimension)

      BiologicalAgeMeter(chronologicalAge: 30.0, biologicalAge: bioAge)
        .frame(square: dimension)

      BiologicalAgeMeter(chronologicalAge: 60.0, biologicalAge: bioAge, centerContentKind: .profileImage)
        .frame(square: dimension)

      BiologicalAgeMeter(chronologicalAge: 42.0, biologicalAge: nil)
        .frame(square: dimension)
    }
  }
  .onAppear {
    bioAge = 42
  }
}
