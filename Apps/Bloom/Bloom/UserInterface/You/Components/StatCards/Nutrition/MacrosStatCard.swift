//
//  MacrosStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import CoreHealth
import HealthKit

struct MacrosStatCard: View {
  let macros: NutritionMonthlySummary.Macros?

  private var macroStatus: (value: String, subtitle: String?, trend: StatCardTrend?) {
    guard let macros, macros.total > 0 else {
      return ("No Data", nil, nil)
    }

    let proteinRange = HealthGoalProvider.shared.recommendedDailyProteinPercentOfDietaryEnergy()
    let carbsRange = HealthGoalProvider.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy()
    let fatRange = HealthGoalProvider.shared.recommendedDailyFatPercentOfDietaryEnergy()

    var imbalances: [(macro: String, issue: String, diff: Double, trend: StatCardTrend)] = []

    // Protein: check if TOO LOW
    if macros.proteinPercent < proteinRange.lowerBound {
      let diff = proteinRange.lowerBound - macros.proteinPercent
      imbalances.append(("Protein", "Deficit", diff, .trendingDown))
    }

    // Carbs: check if TOO HIGH
    if macros.carbsPercent > carbsRange.upperBound {
      let diff = macros.carbsPercent - carbsRange.upperBound
      imbalances.append(("Carbs", "Surplus", diff, .trendingUp))
    }

    // Fat: check if TOO HIGH
    if macros.fatPercent > fatRange.upperBound {
      let diff = macros.fatPercent - fatRange.upperBound
      imbalances.append(("Fat", "Surplus", diff, .trendingUp))
    }

    // Return most out-of-balance, or balanced
    if let worst = imbalances.max(by: { $0.diff < $1.diff }) {
      return (worst.macro, worst.issue, worst.trend)
    }
    return ("Balanced", nil, .ok)
  }

  private var tintColor: AnyShapeStyle {
    guard macros != nil, macros?.total ?? 0 > 0 else {
      return AnyShapeStyle(.gray)
    }
    if macroStatus.subtitle == nil {
      return AnyShapeStyle(.vitalGood)
    }
    return AnyShapeStyle(.vitalWarning)
  }

  var body: some View {
    StatCard(
      symbol: .forkKnife,
      title: "Macros",
      value: macroStatus.value,
      valueStyle: .largeTinted(macroStatus.subtitle),
      trend: macroStatus.trend,
      aspectRatio: 2
    ) {
      macroBar
    }
    .tint(tintColor)
  }
}

private extension MacrosStatCard {

  @ViewBuilder
  var macroBar: some View {
    if let macros, macros.total > 0 {
      GeometryReader { geometry in
        HStack(spacing: 0) {
          Rectangle()
            .fill(Color.protein)
            .frame(width: geometry.size.width * macros.proteinPercent)
          Rectangle()
            .fill(Color.carbohydrates)
            .frame(width: geometry.size.width * macros.carbsPercent)
          Rectangle()
            .fill(Color.fat)
            .frame(width: geometry.size.width * macros.fatPercent)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MacrosStatCard(macros: previewBalancedMacros)
      MacrosStatCard(macros: previewLowProteinMacros)

      MacrosStatCard(macros: previewHighCarbsMacros)
      MacrosStatCard(macros: nil)
    }
  }
}

// Balanced: 20% protein, 50% carbs, 30% fat
private let previewBalancedMacros = NutritionMonthlySummary.Macros(
  protein: HKQuantity(unit: .gram(), doubleValue: 100),      // 400 cal = 20%
  carbohydrates: HKQuantity(unit: .gram(), doubleValue: 250), // 1000 cal = 50%
  fat: HKQuantity(unit: .gram(), doubleValue: 67),           // 600 cal = 30%
  remainderCalories: 0
)

// Low protein: 5% protein, 60% carbs, 35% fat
private let previewLowProteinMacros = NutritionMonthlySummary.Macros(
  protein: HKQuantity(unit: .gram(), doubleValue: 25),       // 100 cal = 5%
  carbohydrates: HKQuantity(unit: .gram(), doubleValue: 300), // 1200 cal = 60%
  fat: HKQuantity(unit: .gram(), doubleValue: 78),           // 700 cal = 35%
  remainderCalories: 0
)

// High carbs: 15% protein, 70% carbs, 15% fat
private let previewHighCarbsMacros = NutritionMonthlySummary.Macros(
  protein: HKQuantity(unit: .gram(), doubleValue: 75),       // 300 cal = 15%
  carbohydrates: HKQuantity(unit: .gram(), doubleValue: 350), // 1400 cal = 70%
  fat: HKQuantity(unit: .gram(), doubleValue: 33),           // 300 cal = 15%
  remainderCalories: 0
)
