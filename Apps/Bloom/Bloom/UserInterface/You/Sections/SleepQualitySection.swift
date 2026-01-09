//
//  SleepQualitySection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import BloomFoundation
import SFSafeSymbols
import DataContainer

struct SleepQualitySection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let summary: SleepVitalsMonthlySummary?
  let bedtimeData: BedtimeChartData?
  let sleepDurationChartData: SleepDurationChartData?
  let averageSleepScore: Double?
  let sleepStageDataPoints: [SleepStageDataPoint]?
  let averageSleepHeartRate: Double?
  let sleepHeartRateChartData: [SleepHeartRateDataPoint]?
  let sleepRespiratoryRateTrend: RespiratoryRateTrend?
  let sleepRespiratoryRateChartData: [RespiratoryRateDataPoint]?
  let wristTempData: WristTempData?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.sleepQuality.systemImage), title: "Sleep Quality", subtitle: "Last 7 Days") {
      HStack {
        SleepBedtimeStatCard(data: bedtimeData)
          .onTapGesture { navigateToBedtimeDetails() }
        SleepDurationStatCard(data: sleepDurationChartData)
          .onTapGesture { navigateToBedtimeDetails() }
      }

      SleepStagesStatCard(sleepStageDataPoints: sleepStageDataPoints)
        .onTapGesture { navigateToSleepStagesDetails() }

      HStack {
        SleepScoreStatCard(score: averageSleepScore)
          .onTapGesture { navigateToSleepScoreDetails() }
        SleepHeartRateStatCard(heartRate: averageSleepHeartRate, chartData: sleepHeartRateChartData)
          .onTapGesture { navigateToDetails() }
      }

      HStack {
        SleepWristTempStatCard(data: wristTempData)
          .onTapGesture { navigateToDetails() }
        SleepRespiratoryRateStatCard(trend: sleepRespiratoryRateTrend, chartData: sleepRespiratoryRateChartData)
          .onTapGesture { navigateToDetails() }
      }
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = SleepDetailsView().asAny
  }

  private func navigateToBedtimeDetails() {
    presentedNavigationDestination = BedtimeSleepDurationDetailsView().asAny
  }

  private func navigateToSleepStagesDetails() {
    presentedNavigationDestination = SleepStagesDetailsView().asAny
  }

  private func navigateToSleepScoreDetails() {
    presentedNavigationDestination = SleepScoreHistoryView().asAny
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      SleepQualitySection(
        presentedNavigationDestination: .constant(nil),
        summary: nil,
        bedtimeData: nil,
        sleepDurationChartData: nil,
        averageSleepScore: nil,
        sleepStageDataPoints: nil,
        averageSleepHeartRate: nil,
        sleepHeartRateChartData: nil,
        sleepRespiratoryRateTrend: nil,
        sleepRespiratoryRateChartData: nil,
        wristTempData: nil
      )
    }
  }
}
