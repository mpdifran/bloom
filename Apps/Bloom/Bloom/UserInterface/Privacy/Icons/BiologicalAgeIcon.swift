//
//  BiologicalAgeIcon.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-01.
//

import SwiftUI
import BloomFoundation

private extension TimeInterval {
  static let animationDuration: TimeInterval = 1 // s
  static let onPause: TimeInterval = 4 // s
  static let offPause: TimeInterval = 1 // s
}

private extension Int {
  static let offsetDelay: Int = 100 // ms
  static let ageDelay: Int = 3000 // ms
}

struct BiologicalAgeIcon: View {

  @State private var showChatBubble = true
  @State private var showResponseRect = true
  @State private var bioAge = 25
  @State private var ageIndex = 0

  private let ages = [27, 38, 22, 35]

  var body: some View {
    GeometryReader { proxy in
      RoundedRectangle(cornerRadius: outerCornerRadius(for: proxy))
        .fill(.background.secondary)
        .overlay {
          VStack(spacing: padding(for: proxy)) {

            if showChatBubble {
              MiniBioAgeMeter(chronologicalAge: 30, biologicalAge: Double(bioAge))
                .frame(height: proxy.size.width * 0.7)
                .transition(.opacity)
            }

            Spacer(minLength: 0)

            if showResponseRect {
              RoundedRectangle(cornerRadius: innerCornerRadius(for: proxy))
                .fill(.fill)
                .shimmer()
                .transition(.scale(scale: 0.1, anchor: .bottom).combined(with: .opacity))
            }
          }
          .padding(padding(for: proxy))
          .horizontallyCentered()
          .clipShape(RoundedRectangle(cornerRadius: outerCornerRadius(for: proxy)))
        }
        .clipped()
    }
    .aspectRatio(6/9, contentMode: .fit)
    .animation(.bouncy(duration: .animationDuration), value: showChatBubble)
    .animation(.bouncy(duration: .animationDuration), value: showResponseRect)
    .onAppear {
      Task {
        await runAgeLoop()
      }
    }
  }
}

private extension BiologicalAgeIcon {

  func outerCornerRadius(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 4
  }

  func padding(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 10
  }

  func bubbleScale(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 100
  }

  func innerCornerRadius(for proxy: GeometryProxy) -> CGFloat {
    outerCornerRadius(for: proxy) - padding(for: proxy)
  }
}

private extension BiologicalAgeIcon {

  func runAgeLoop() async {
    while true {
      ageIndex = (ageIndex + 1) % ages.count
      self.bioAge = ages[ageIndex]
      await Delay(.ageDelay)
    }
  }

  func runAnimationLoop() async {
    while true {
      await animateSequenceIn()
      try? await Task.sleep(for: .seconds(.onPause))
      await animateSequenceOut()
      try? await Task.sleep(for: .seconds(.offPause))
    }
  }

  func animateSequenceIn() async {
    showChatBubble = true
    await Delay(.offsetDelay)
    showResponseRect = true
  }

  func animateSequenceOut() async {
    showResponseRect = false
    await Delay(.offsetDelay)
    showChatBubble = false
  }
}

private struct MiniBioAgeMeter: View {
  let chronologicalAge: Int
  let biologicalAge: Double?

  private let startAngle = 0.125 // 7:00 position
  private let endAngle = 0.875   // 5:00 position
  private let centerAngle = 0.5  // 12:00 position (neutral)
  private let maxAgeDifference = 10.0

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
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .aspectRatio(1, contentMode: .fit)
    .animation(.easeInOut(duration: 1.5), value: biologicalAge)
  }
}

private extension MiniBioAgeMeter {

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
  PreviewEnvironment {
    BloomScrollView {
      BiologicalAgeIcon()
        .frame(width: 40)

      BiologicalAgeIcon()
        .frame(width: 80)

      BiologicalAgeIcon()
        .frame(width: 120)
    }
  }
}
