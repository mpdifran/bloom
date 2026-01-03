//
//  BodyCompositionSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import DataContainer

struct BodyCompositionSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let summary: BodyCompositionMonthlySummary?
  let bodyWeightChartData: BodyWeightChartData?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.bodyComposition.systemImage), title: "Body Composition", subtitle: "Last 30 Days") {
      HStack {
        bodyWeightCard
        bodyFatCard
      }
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = BodyCompositionDetailsView().asAny
  }
}

private extension BodyCompositionSection {

  var bodyWeightCard: some View {
    BodyWeightStatCard(chartData: bodyWeightChartData)
      .onTapGesture { navigateToDetails() }
  }

  var bodyFatCard: some View {
    BodyFatStatCard(bodyFatPercentage: summary?.details.bodyFatPercentage)
      .onTapGesture { navigateToDetails() }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BodyCompositionSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil,
        bodyWeightChartData: nil
      )
    }
  }
}
