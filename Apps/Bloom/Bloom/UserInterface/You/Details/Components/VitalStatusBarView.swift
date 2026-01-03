//
//  VitalStatusBarView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-26.
//

import SwiftUI
import DataContainer

private extension CGFloat {
  static let expandedRectangleWidth: CGFloat = 30
  static let rectangleHeight: CGFloat = 14
  static let circleDiameter: CGFloat = 10
}

private extension Double {
  static let colorFillOpacity: CGFloat = 0.4
}

extension VitalStatusBarView {
  enum Level: CaseIterable, Identifiable {
    var id: Self { self }

    case low
    case medium
    case high
    case optimal

    init(barLevel: VitalModel.Level) {
      switch barLevel {
      case .low: self = .low
      case .medium: self = .medium
      case .high: self = .high
      case .optimal: self = .optimal
      @unknown default: fatalError("Unhandled Case")
      }
    }

    var color: Color {
      switch self {
      case .low:
          .vitalSevere
      case .medium:
          .vitalWarning
      case .high:
          .vitalGood
      case .optimal:
          .vitalGreat
      }
    }
  }
}

struct VitalStatusBarView: View {
  let level: Level?
  let levelPercent: Double?

  var body: some View {
    HStack(spacing: 2) {
      ForEach(Level.allCases) { levelCase in
        createRectangleShape(for: levelCase)
          .frame(width: level == levelCase ? .expandedRectangleWidth : .rectangleHeight)
          .overlay {
            if level == levelCase, let clampedPercent {
              HStack {
                Circle()
                  .fill(levelCase.color)
                  .frame(square: .circleDiameter)
                  .padding(.leading, leadingPadding(for: clampedPercent))
                  .transition(.scale)
                Spacer(minLength: 0)
              }
              .frame(width: .expandedRectangleWidth)
            }
          }
      }
    }
    .frame(height: .rectangleHeight)
    .animation(.bouncy, value: level)
    .animation(.bouncy, value: levelPercent)
  }
}

private extension VitalStatusBarView {

  var clampedPercent: Double? {
    guard let levelPercent else { return nil }

    return max(min(1, levelPercent), 0)
  }

  func leadingPadding(for clampedPercent: Double) -> CGFloat {
    let widthMinusPadding = CGFloat.expandedRectangleWidth - (2 * dotInternalPadding) - .circleDiameter
    let percentageWidth = widthMinusPadding * clampedPercent

    return percentageWidth + dotInternalPadding
  }

  var dotInternalPadding: CGFloat {
    (CGFloat.rectangleHeight - CGFloat.circleDiameter) / 2
  }

  func createRectangleShape(for level: Level) -> some View {
    Capsule()
      .fill(level.color.tertiary)
  }
}

#Preview {
  VStack {
    VitalStatusBarView(level: .low, levelPercent: 0.5)
    VitalStatusBarView(level: .medium, levelPercent: 0)
    VitalStatusBarView(level: .high, levelPercent: 1)
    VitalStatusBarView(level: .optimal, levelPercent: 0.75)
    VitalStatusBarView(level: nil, levelPercent: nil)
  }
}
