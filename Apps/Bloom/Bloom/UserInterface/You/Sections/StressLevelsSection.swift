//
//  StressLevelsSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import DataContainer

struct StressLevelsSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let hrvChartData: HRVChartData?
  let bloodPressureData: BloodPressureCardData?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.stressLevels.systemImage), title: "Stress Levels", subtitle: "Last 7 Days") {
      HStack {
        hrvCard
        bloodPressureCard
      }
    }
  }

  private func navigateToHRVDetails() {
    presentedNavigationDestination = HRVDetailsView().asAny
  }

  private func navigateToBloodPressureDetails() {
    presentedNavigationDestination = BloodPressureDetailsView().asAny
  }
}

private extension StressLevelsSection {

  var hrvCard: some View {
    HRVStatCard(data: hrvChartData)
      .onTapGesture { navigateToHRVDetails() }
  }

  var bloodPressureCard: some View {
    BloodPressureStatCard(data: bloodPressureData)
      .onTapGesture { navigateToBloodPressureDetails() }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      StressLevelsSection(
        presentedNavigationDestination: .constant(nil),
        hrvChartData: nil,
        bloodPressureData: nil
      )
    }
  }
}
