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
import HealthKit

struct BodyCompositionSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let bodyFatPercentage: HKQuantity?
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
    BodyFatStatCard(bodyFatPercentage: bodyFatPercentage)
      .onTapGesture { navigateToDetails() }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BodyCompositionSection(
        presentedNavigationDestination: .constant(nil),
        bodyFatPercentage: nil,
        bodyWeightChartData: nil
      )
    }
  }
}
