//
//  NutritionSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import HealthKit
import SFSafeSymbols
import DataContainer

struct NutritionSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let summary: NutritionMonthlySummary?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.nutrition.systemImage), title: "Nutrition", subtitle: "Last 7 Days") {
      HStack {
        proteinCard
        carbsCard
      }

      HStack {
        fatCard
        netEnergyCard
      }

      HStack {
        fiberCard
        sugarCard
      }
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = NutritionDetailsView().asAny
  }
}

private extension NutritionSection {

  var macros: NutritionMonthlySummary.Macros? {
    guard
      let protein = summary?.details.averageProtein,
      let carbs = summary?.details.averageCarbohydrates,
      let fat = summary?.details.averageFat
    else { return nil }

    return NutritionMonthlySummary.Macros(
      protein: protein,
      carbohydrates: carbs,
      fat: fat,
      remainderCalories: 0
    )
  }

  @ViewBuilder
  var proteinCard: some View {
    if let macros, macros.total > 0 {
      let percent = macros.proteinPercent
      GaugeCard(
        title: "Protein",
        value: "\(Int(percent * 100))%",
        progress: percent,
        symbol: .forkKnife,
        color: .red
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Protein", symbol: .forkKnife)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var carbsCard: some View {
    if let macros, macros.total > 0 {
      let percent = macros.carbsPercent
      GaugeCard(
        title: "Carbs",
        value: "\(Int(percent * 100))%",
        progress: percent,
        symbol: .leafFill,
        color: .yellow
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Carbs", symbol: .leafFill)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var fatCard: some View {
    if let macros, macros.total > 0 {
      let percent = macros.fatPercent
      GaugeCard(
        title: "Fat",
        value: "\(Int(percent * 100))%",
        progress: percent,
        symbol: .dropFill,
        color: .blue
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Fat", symbol: .dropFill)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var netEnergyCard: some View {
    if let netEnergyStatus = summary?.details.netEnergyStatus {
      switch netEnergyStatus {
      case .deficit:
        StatusIndicatorCard(
          title: "Net Energy",
          status: "Deficit",
          level: .high,
          symbol: .flameFill
        )
        .onTapGesture { navigateToDetails() }
      case .surplus:
        StatusIndicatorCard(
          title: "Net Energy",
          status: "Surplus",
          level: .medium,
          symbol: .flameFill
        )
        .onTapGesture { navigateToDetails() }
      }
    } else {
      NoDataCard(title: "Net Energy", symbol: .flameFill)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var fiberCard: some View {
    if let fiber = summary?.details.averageFiber {
      let fiberGrams = fiber.doubleValue(for: .gram())
      let goal: Double = 25 // Default fiber goal
      let progress = fiberGrams / goal
      LinearProgressCard(
        title: "Fiber",
        value: "\(Int(fiberGrams))g / \(Int(goal))g",
        progress: progress,
        symbol: .leafFill,
        color: .green
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Fiber", symbol: .leafFill)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var sugarCard: some View {
    if let sugar = summary?.details.averageSugar {
      let sugarGrams = sugar.doubleValue(for: .gram())
      BigNumberCard(
        title: "Sugar",
        value: "\(Int(sugarGrams))",
        unit: "g",
        symbol: .cubeBox,
        color: .pink
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Sugar", symbol: .cubeBox)
        .onTapGesture { navigateToDetails() }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      NutritionSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil
      )
    }
  }
}
