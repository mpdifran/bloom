//
//  MonitorIcon.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-16.
//

import SwiftUI
import BloomFoundation

private extension Int {
  static let barDelay: Int = 3000 // ms
}

struct MonitorIcon: View {
  let isEnabled: Bool

  @State private var metricZScore: Double = 0.2
  @State private var minZScore: Double = -0.5
  @State private var maxZScore: Double = 0.8
  @State private var stateIndex = 0

  // Predefined animation states (minZ, maxZ, metricZ)
  private let states: [(min: Double, max: Double, metric: Double)] = [
    (-1.0, 1.0, 1.0),     // Centered - spans all zones
    (-0.8, 2.8, 2.2),      // High alert - far right, all orange
    (-2.8, 0.2, 1.5),   // Low alert - far left, all blue
    (-2.5, 2.5, 1.2),     // Full span - entire bar visible
  ]

  var body: some View {
    GeometryReader { proxy in
      RoundedRectangle(cornerRadius: outerCornerRadius(for: proxy))
        .fill(.background.secondary)
        .overlay {
          VStack(spacing: padding(for: proxy)) {
            RoundedRectangle(cornerRadius: innerCornerRadius(for: proxy))
              .fill(.fill)
              .if(isEnabled) {
                $0.shimmer()
              }
              .transition(.scale(scale: 0.1, anchor: .bottom).combined(with: .opacity))

            MiniMonitorBar(
              metricZScore: metricZScore,
              minZScore: minZScore,
              maxZScore: maxZScore
            )
            .frame(height: proxy.size.width * 0.15)
          }
          .padding(padding(for: proxy))
          .horizontallyCentered()
          .clipShape(RoundedRectangle(cornerRadius: outerCornerRadius(for: proxy)))
        }
    }
    .aspectRatio(6/9, contentMode: .fit)
    .animation(.default, value: isEnabled)
    .saturation(isEnabled ? 1 : 0)
    .onChange(of: isEnabled) { oldValue, newValue in
      if newValue {
        Task {
          await runBarLoop()
        }
      } else {
        // Reset to default state
        minZScore = -0.5
        maxZScore = 0.8
        metricZScore = 0.2
      }
    }
    .onAppear {
      if isEnabled {
        Task {
          await runBarLoop()
        }
      }
    }
  }
}

private extension MonitorIcon {

  func runBarLoop() async {
    while isEnabled {
      await Delay(.barDelay)
      stateIndex = (stateIndex + 1) % states.count
      let state = states[stateIndex]
      minZScore = state.min
      maxZScore = state.max
      metricZScore = state.metric
    }
  }

  func outerCornerRadius(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 4
  }

  func padding(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 10
  }

  func innerCornerRadius(for proxy: GeometryProxy) -> CGFloat {
    outerCornerRadius(for: proxy) - padding(for: proxy)
  }
}

// MARK: - Mini Monitor Bar

private struct MiniMonitorBar: View {
  let metricZScore: Double
  let minZScore: Double
  let maxZScore: Double

  private let displayRange: Double = 3.0 // Display from -3 to +3
  private let lowThreshold: Double = -1.0
  private let highThreshold: Double = 1.0

  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let height = geometry.size.height

      ZStack {
        // Background zones (Low | Normal | High)
        zoneBackground(width: width, height: height)

        // Range bar overlay
        rangeBar(width: width, height: height)

        // Metric dot
        metricDot(width: width, height: height)
      }
    }
  }

  // MARK: - Components

  private func zoneBackground(width: CGFloat, height: CGFloat) -> some View {
    HStack(spacing: 0) {
      Rectangle()
        .fill(Color(.systemGray5))
        .frame(width: width / 3)

      Rectangle()
        .fill(Color(.systemGray6))
        .frame(width: width / 3)

      Rectangle()
        .fill(Color(.systemGray5))
        .frame(width: width / 3)
    }
    .frame(height: height)
    .clipShape(Capsule())
  }

  private func rangeBar(width: CGFloat, height: CGFloat) -> some View {
    let startPosition = normalizedPosition(for: minZScore)
    let endPosition = normalizedPosition(for: maxZScore)
    let barWidth = width * (endPosition - startPosition)
    let xOffset = width * startPosition + barWidth / 2 - width / 2

    return Capsule()
      .fill(rangeBarGradient(startPos: startPosition, endPos: endPosition))
      .frame(width: max(barWidth, 2), height: height - 1)
      .offset(x: xOffset)
      .animation(.easeInOut(duration: 1.0), value: minZScore)
      .animation(.easeInOut(duration: 1.0), value: maxZScore)
  }

  private func metricDot(width: CGFloat, height: CGFloat) -> some View {
    let dotSize = height * 0.6
    let inset = (height - dotSize) / 2

    let startPosition = normalizedPosition(for: minZScore)
    let endPosition = normalizedPosition(for: maxZScore)
    let barStartX = width * startPosition
    let barEndX = width * endPosition
    let minDotCenterX = barStartX + inset + dotSize / 2
    let maxDotCenterX = barEndX - inset - dotSize / 2

    let metricPosition = normalizedPosition(for: metricZScore)
    let rawX = width * metricPosition
    let clampedX = min(max(rawX, minDotCenterX), maxDotCenterX)
    let xOffset = clampedX - width / 2

    return Circle()
      .fill(Color.black)
      .frame(width: dotSize, height: dotSize)
      .offset(x: xOffset)
      .animation(.easeInOut(duration: 1.0), value: metricZScore)
      .animation(.easeInOut(duration: 1.0), value: minZScore)
      .animation(.easeInOut(duration: 1.0), value: maxZScore)
  }

  // MARK: - Helpers

  private func normalizedPosition(for zScore: Double) -> Double {
    let clamped = min(max(zScore, -displayRange), displayRange)
    return (clamped + displayRange) / (displayRange * 2)
  }

  private func rangeBarGradient(startPos: Double, endPos: Double) -> LinearGradient {
    let barSpan = endPos - startPos
    guard barSpan > 0.001 else {
      return LinearGradient(
        colors: [colorForPosition(startPos)],
        startPoint: .leading,
        endPoint: .trailing
      )
    }

    let lowBoundary = normalizedPosition(for: lowThreshold)
    let highBoundary = normalizedPosition(for: highThreshold)

    func toLocalSpace(_ globalPos: Double) -> Double {
      max(0, min(1, (globalPos - startPos) / barSpan))
    }

    let transitionWidth = 0.30
    var stops: [Gradient.Stop] = []

    let startColor = colorForPosition(startPos)
    stops.append(Gradient.Stop(color: startColor, location: 0))

    if startPos < lowBoundary && endPos > lowBoundary {
      let localPos = toLocalSpace(lowBoundary)
      let transitionStart = max(0, localPos - transitionWidth / 2)
      let transitionEnd = min(1, localPos + transitionWidth / 2)
      stops.append(Gradient.Stop(color: .monitorLow, location: transitionStart))
      stops.append(Gradient.Stop(color: .monitorTypical, location: transitionEnd))
    }

    if startPos < highBoundary && endPos > highBoundary {
      let localPos = toLocalSpace(highBoundary)
      let transitionStart = max(0, localPos - transitionWidth / 2)
      let transitionEnd = min(1, localPos + transitionWidth / 2)
      stops.append(Gradient.Stop(color: .monitorTypical, location: transitionStart))
      stops.append(Gradient.Stop(color: .monitorHigh, location: transitionEnd))
    }

    let endColor = colorForPosition(endPos)
    stops.append(Gradient.Stop(color: endColor, location: 1))

    return LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
  }

  private func colorForPosition(_ position: Double) -> Color {
    let lowBoundary = normalizedPosition(for: lowThreshold)
    let highBoundary = normalizedPosition(for: highThreshold)

    if position < lowBoundary {
      return .monitorLow
    } else if position < highBoundary {
      return .monitorTypical
    } else {
      return .monitorHigh
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MonitorIcon(isEnabled: true)
        .frame(width: 40)
      MonitorIcon(isEnabled: false)
        .frame(width: 80)
      MonitorIcon(isEnabled: true)
        .frame(width: 120)
    }
  }
}
