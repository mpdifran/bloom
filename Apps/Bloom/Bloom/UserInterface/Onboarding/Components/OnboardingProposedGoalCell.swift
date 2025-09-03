//
//  OnboardingProposedGoalCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-02.
//

import SwiftUI
import HealthKit
import CoreHealth
import DataContainer
import SFSafeSymbols

struct OnboardingProposedGoalCell: View {
  let targetMetric: TargetMetric
  let averageQuantity: HKQuantity
  let targetQuantity: HKQuantity
  let isWeekly: Bool
  let hasAdded: Bool

  var body: some View {
    HStack {
      Image(systemSymbol: SFSymbol(rawValue: targetMetric.systemImage))
        .font(.title)
        .foregroundStyle(.tint)
        .frame(width: 45)

      VStack(alignment: .leading) {
        Text(targetMetric.name)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
        Group {
          Text(isWeekly ? "Weekly" : "Daily")
          + Text(" • ")
          + Text("Avg: \(averageQuantity.displayString(for: targetMetric.defaultUnit))")
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(.secondary)
        .font(.subheadline)
      }

      Spacer()

      Text(targetQuantity.displayString(for: targetMetric.defaultUnit))
        .foregroundStyle(.tint)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)

      Group {
        if hasAdded {
          Image(systemSymbol: .checkmarkCircleFill)
            .foregroundStyle(.tint, .fill)
        } else {
          Image(systemSymbol: .plusCircleFill)
            .foregroundStyle(.white, .tint)
        }
      }
      .font(.title2)
      .bold()
    }
    .tint(targetMetric.color)
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      OnboardingProposedGoalCell(
        targetMetric: .bikeDistance,
        averageQuantity: HKQuantity(unit: .meterUnit(with: .kilo), doubleValue: 13),
        targetQuantity: HKQuantity(unit: .meterUnit(with: .kilo), doubleValue: 20),
        isWeekly: true,
        hasAdded: false
      )
      OnboardingProposedGoalCell(
        targetMetric: .stepCount,
        averageQuantity: HKQuantity(unit: .count(), doubleValue: 3400),
        targetQuantity: HKQuantity(unit: .count(), doubleValue: 5000),
        isWeekly: false,
        hasAdded: true
      )
    }
  }
}
