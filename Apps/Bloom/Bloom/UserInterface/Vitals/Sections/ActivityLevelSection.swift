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

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.activityLevel.systemImage), title: "Activity Level", subtitle: "Last 7 Days") {
      HStack {
        ActiveEnergyStatCard(activeEnergy: summary?.details.averageActiveEnergyBurned)
          .onTapGesture { navigateToDetails() }
        ActivityLevelStatCard(level: summary?.details.activityLevel)
          .onTapGesture { navigateToDetails() }
      }

      StepsStatCard(chartData: weeklyStepsChartData)
        .onTapGesture { navigateToDetails() }
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = ActivityLevelDetailsView().asAny
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ActivityLevelSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil,
        weeklyStepsChartData: nil
      )
    }
  }
}
