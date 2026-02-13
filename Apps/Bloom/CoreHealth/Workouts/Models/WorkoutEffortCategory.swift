//
//  WorkoutEffortCategory.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-02-11.
//

import SwiftUI

public enum WorkoutEffortCategory: String, Sendable, CaseIterable {
  case easy = "Easy"
  case moderate = "Moderate"
  case hard = "Hard"
  case allOut = "All Out"

  public init(effortScore: Double) {
    switch effortScore {
    case ...3: self = .easy
    case 4...6: self = .moderate
    case 7...8: self = .hard
    default: self = .allOut
    }
  }

  public var color: Color {
    switch self {
    case .easy: .cyan
    case .moderate: .indigo
    case .hard: .purple
    case .allOut: .pink
    }
  }

  public var cardBackgroundColor: Color {
    switch self {
    case .easy: Color(hue: 0.57, saturation: 0.6, brightness: 0.35)
    case .moderate: Color(hue: 0.68, saturation: 0.65, brightness: 0.35)
    case .hard: Color(hue: 0.78, saturation: 0.6, brightness: 0.4)
    case .allOut: Color(hue: 0.92, saturation: 0.55, brightness: 0.45)
    }
  }

  public var range: ClosedRange<Int> {
    switch self {
    case .easy: 1...3
    case .moderate: 4...6
    case .hard: 7...8
    case .allOut: 9...10
    }
  }

  public static func category(for level: Int) -> WorkoutEffortCategory {
    WorkoutEffortCategory(effortScore: Double(level))
  }
}
