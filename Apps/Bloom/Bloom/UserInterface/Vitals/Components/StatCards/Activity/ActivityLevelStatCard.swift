//
//  ActivityLevelStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI
import CoreHealth

struct ActivityLevelStatCard: View {
  let level: ActivityLevelSummary.ActivityLevel?

  var body: some View {
    StatCard(
      symbol: .figureTennis,
      title: "Activity Level",
      value: nil
    ) {
      levelContent
    }
    .tint(level?.color ?? .gray)
  }
}

private extension ActivityLevelStatCard {

  @ViewBuilder
  var levelContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      Spacer(minLength: 0)

      HStack(spacing: 4) {
        ForEach(0..<5, id: \.self) { index in
          Capsule()
            .fill(index <= (level?.levelIndex ?? -1) ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.secondary.opacity(0.2)))
            .frame(height: 8)
        }
      }

      Text(level?.name ?? "No Data")
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(level == nil ? .secondary : .primary)
    }
  }
}

private extension ActivityLevelSummary.ActivityLevel {

  var color: Color {
    switch self {
    case .sedentary: .mutedYellow
    case .light, .moderate: .mutedGreen
    case .high, .intense: .mutedBlue
    @unknown default:
        .gray
    }
  }

  var levelIndex: Int {
    switch self {
    case .sedentary: 0
    case .light: 1
    case .moderate: 2
    case .high: 3
    case .intense: 4
    @unknown default:
        0
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        ActivityLevelStatCard(level: .sedentary)
        ActivityLevelStatCard(level: .light)
      }
      HStack {
        ActivityLevelStatCard(level: .moderate)
        ActivityLevelStatCard(level: .high)
      }
      HStack {
        ActivityLevelStatCard(level: .intense)
        ActivityLevelStatCard(level: nil)
      }
    }
  }
}
