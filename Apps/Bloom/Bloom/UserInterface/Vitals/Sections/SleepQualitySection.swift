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
          .onTapGesture { navigateToDetails() }
        SleepDurationStatCard(data: sleepDurationChartData)
          .onTapGesture { navigateToDetails() }
      }

      SleepStagesStatCard(sleepStageDataPoints: sleepStageDataPoints)
        .onTapGesture { navigateToDetails() }

      HStack {
        SleepScoreStatCard(score: averageSleepScore)
          .onTapGesture { navigateToDetails() }
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
