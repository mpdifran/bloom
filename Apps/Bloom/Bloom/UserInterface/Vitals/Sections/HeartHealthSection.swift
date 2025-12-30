//
//  HeartHealthSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import HealthKit
import SFSafeSymbols
import DataContainer

struct HeartHealthSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let summary: HeartHealthMonthlySummary?
  let maxHeartRateChartData: MaxHeartRateChartData?
  let vo2MaxTrendData: VO2MaxTrendData?
  let heartRateRecoveryData: HeartRateRecoveryData?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.heartHealth.systemImage), title: "Heart Health", subtitle: "Last 7 Days") {
      HStack {
        restingHeartRateCard
        vo2MaxCard
      }

      HStack {
        maxHeartRateCard
        heartRateRecoveryCard
      }
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = HeartHealthDetailsView().asAny
  }
}

private extension HeartHealthSection {

  var restingHeartRateCard: some View {
    RestingHeartRateStatCard(
      restingHeartRate: summary?.details.averageRestingHeartRate?.doubleValue(for: .bpm())
    )
    .onTapGesture { navigateToDetails() }
  }

  var maxHeartRateCard: some View {
    MaxHeartRateStatCard(chartData: maxHeartRateChartData)
      .onTapGesture { navigateToDetails() }
  }

  var vo2MaxCard: some View {
    VO2MaxStatCard(trendData: vo2MaxTrendData)
      .onTapGesture { navigateToDetails() }
  }

  var heartRateRecoveryCard: some View {
    HeartRateRecoveryStatCard(data: heartRateRecoveryData)
      .onTapGesture { navigateToDetails() }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HeartHealthSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil,
        maxHeartRateChartData: nil,
        vo2MaxTrendData: nil,
        heartRateRecoveryData: nil
      )
    }
  }
}
