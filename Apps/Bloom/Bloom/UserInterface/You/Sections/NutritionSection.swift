//
//  NutritionSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import DataContainer

struct NutritionSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let macros: NutritionMonthlySummary.Macros?
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

  var macrosCard: some View {
    MacrosStatCard(macros: macros)
      .onTapGesture { navigateToDetails() }
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
        macros: nil,
        fiberChartData: nil,
        sugarChartData: nil
      )
    }
  }
}
