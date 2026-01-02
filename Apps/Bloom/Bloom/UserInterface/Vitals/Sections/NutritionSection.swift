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
  let fiberChartData: FiberChartData?
  let sugarChartData: SugarChartData?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.nutrition.systemImage), title: "Nutrition", subtitle: "Last 7 Days") {
      macrosCard

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

  var macrosCard: some View {
    MacrosStatCard(macros: macros)
      .onTapGesture { navigateToDetails() }
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

  var fiberCard: some View {
    FiberStatCard(data: fiberChartData)
      .onTapGesture { navigateToDetails() }
  }

  var sugarCard: some View {
    SugarStatCard(data: sugarChartData)
      .onTapGesture { navigateToDetails() }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      NutritionSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil,
        fiberChartData: nil,
        sugarChartData: nil
      )
    }
  }
}
