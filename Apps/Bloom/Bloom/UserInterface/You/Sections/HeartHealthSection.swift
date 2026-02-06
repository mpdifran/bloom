//
//  HeartHealthSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import DataContainer

struct HeartHealthSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let averageRestingHeartRate: Double?
  let heartRateReserveChartData: HeartRateReserveChartData?
  let vo2MaxTrendData: VO2MaxTrendData?
  let heartRateRecoveryData: HeartRateRecoveryData?
  let restingHeartRateChartData: [RestingHeartRateDataPoint]?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.heartHealth.systemImage), title: "Heart Health", subtitle: "Last 7 Days") {
      HStack {
        restingHeartRateCard
        vo2MaxCard
      }

      HStack {
        heartRateReserveCard
        heartRateRecoveryCard
      }
    }
  }

  private func navigateToHeartHealthDetails() {
    presentedNavigationDestination = HeartHealthDetailsView().asAny
  }

  private func navigateToVO2MaxDetails() {
    presentedNavigationDestination = VO2MaxDetailsView().asAny
  }
}

private extension HeartHealthSection {

  var restingHeartRateCard: some View {
    RestingHeartRateStatCard(
      restingHeartRate: averageRestingHeartRate,
      chartData: restingHeartRateChartData
    )
    .onTapGesture { navigateToHeartHealthDetails() }
  }

  var heartRateReserveCard: some View {
    HeartRateReserveStatCard(chartData: heartRateReserveChartData)
      .onTapGesture { navigateToHeartHealthDetails() }
  }

  var vo2MaxCard: some View {
    VO2MaxStatCard(trendData: vo2MaxTrendData)
      .onTapGesture { navigateToVO2MaxDetails() }
  }

  var heartRateRecoveryCard: some View {
    HeartRateRecoveryStatCard(data: heartRateRecoveryData)
      .onTapGesture { navigateToHeartHealthDetails() }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HeartHealthSection(
        presentedNavigationDestination: .constant(nil),
        averageRestingHeartRate: nil,
        heartRateReserveChartData: nil,
        vo2MaxTrendData: nil,
        heartRateRecoveryData: nil,
        restingHeartRateChartData: nil
      )
    }
  }
}
