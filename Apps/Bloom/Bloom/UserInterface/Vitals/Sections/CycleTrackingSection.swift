//
//  CycleTrackingSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import BloomFoundation
import DataContainer

struct CycleTrackingSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let summary: MenstrualSummary?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.cycleTracking.systemImage), title: "Cycle Tracking", subtitle: "Current Cycle") {
      HStack {
        CycleDurationStatCard(summary: summary)
          .onTapGesture { navigateToDetails() }
        NextPeriodStatCard(summary: summary)
          .onTapGesture { navigateToDetails() }
      }

      CurrentPhaseStatCard(summary: summary)
        .onTapGesture { navigateToDetails() }
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = MenstruationDetailView().asAny
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      CycleTrackingSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil
      )
    }
  }
}
