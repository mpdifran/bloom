//
//  LifestyleSection.swift
//  Bloom
//
//  Created by Claude on 2026-01-24.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import DataContainer

struct LifestyleSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let alcoholSummary: AlcoholSummary?
  let smokingStatus: SmokingStatus
  let smokingQuitDate: Date?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.lifestyle.systemImage), title: "Lifestyle", subtitle: "Last 7 Days") {
      HStack {
        alcoholCard
        smokingCard
      }
    }
  }

  private func navigateToAlcoholDetails() {
    presentedNavigationDestination = AlcoholDetailsView().asAny
  }

  private func navigateToSmokingDetails() {
    presentedNavigationDestination = SmokingDetailsView().asAny
  }
}

private extension LifestyleSection {

  var alcoholCard: some View {
    AlcoholStatCard(summary: alcoholSummary)
      .onTapGesture { navigateToAlcoholDetails() }
  }

  var smokingCard: some View {
    SmokingStatCard(status: smokingStatus, quitDate: smokingQuitDate)
      .onTapGesture { navigateToSmokingDetails() }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      LifestyleSection(
        presentedNavigationDestination: .constant(nil),
        alcoholSummary: AlcoholSummary(
          weeklyTotal: 8,
          dailyData: [
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-6 * 86400), drinks: 0),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-5 * 86400), drinks: 2),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-4 * 86400), drinks: 0),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-3 * 86400), drinks: 3),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-2 * 86400), drinks: 0),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-1 * 86400), drinks: 2),
            AlcoholSummary.DailyAlcoholData(date: Date(), drinks: 1)
          ],
          bingeDays: 0,
          heavyDays: 0
        ),
        smokingStatus: .never,
        smokingQuitDate: nil
      )
    }
  }
}
