//
//  ActivityLevelSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import DataContainer

struct ActivityLevelSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let summary: ActivityLevelSummary?
  let weeklyStepsChartData: WeeklyStepsChartData?
  let activeEnergyChartData: ActiveEnergyChartData?
  let walkingSpeedChartData: WalkingSpeedChartData?
  let stairClimbSpeedChartData: StairClimbSpeedChartData?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.activityLevel.systemImage), title: "Activity Level", subtitle: "Last 7 Days") {
      HStack {
        ActiveEnergyStatCard(data: activeEnergyChartData)
          .onTapGesture { navigateToActivityLevelDetails() }
        ActivityLevelStatCard(level: summary?.details.activityLevel)
          .onTapGesture { navigateToActivityLevelDetails() }
      }

      StepsStatCard(chartData: weeklyStepsChartData)
        .onTapGesture { navigateToMobilityDetails() }

      HStack {
        WalkingSpeedStatCard(chartData: walkingSpeedChartData)
          .onTapGesture { navigateToMobilityDetails() }
        StairClimbSpeedStatCard(chartData: stairClimbSpeedChartData)
          .onTapGesture { navigateToMobilityDetails() }
      }
    }
  }

  private func navigateToActivityLevelDetails() {
    presentedNavigationDestination = ActivityLevelDetailsView().asAny
  }

  private func navigateToMobilityDetails() {
    presentedNavigationDestination = MobilityDetailsView().asAny
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ActivityLevelSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil,
        weeklyStepsChartData: nil,
        activeEnergyChartData: nil,
        walkingSpeedChartData: nil,
        stairClimbSpeedChartData: nil
      )
    }
  }
}
