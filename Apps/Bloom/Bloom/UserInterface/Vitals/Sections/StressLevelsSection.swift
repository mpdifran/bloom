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
  let summary: StressMonthlySummary?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.stressLevels.systemImage), title: "Stress Levels", subtitle: "Last 7 Days") {
      HStack {
        hrvCard
        bloodPressureCard
      }
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = StressDetailsView().asAny
  }
}

private extension StressLevelsSection {

  @ViewBuilder
  var hrvCard: some View {
    if let hrv = summary?.details.averageHeartRateVariability {
      BigNumberCard(
        title: "HRV",
        value: "\(Int(hrv))",
        unit: "ms",
        symbol: .waveformPathEcg,
        color: .teal
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "HRV", symbol: .waveformPathEcg)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var bloodPressureCard: some View {
    if let systolic = summary?.details.averageSystolic,
       let diastolic = summary?.details.averageDiastolic {
      BigNumberCard(
        title: "Blood Pressure",
        value: "\(Int(systolic))/\(Int(diastolic))",
        unit: "mmHg",
        symbol: .heartFill,
        color: .red
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Blood Pressure", symbol: .heartFill)
        .onTapGesture { navigateToDetails() }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      StressLevelsSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil
      )
    }
  }
}
