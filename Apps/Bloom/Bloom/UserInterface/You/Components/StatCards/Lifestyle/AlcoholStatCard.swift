//
//  AlcoholStatCard.swift
//  Bloom
//
//  Created by Claude on 2026-01-24.
//

import SwiftUI
import CoreHealth

struct AlcoholStatCard: View {
  let summary: AlcoholSummary?

  var body: some View {
    if let summary, summary.hasData {
      StatCard(
        symbol: .wineglassFill,
        title: "Alcohol",
        value: summary.weeklyTotalDisplayString,
        valueStyle: .largeTinted(String(localized: "this week", comment: "Stat card subtitle: the value covers this week"))
      ) {
        barChart(summary: summary)
      }
      .tint(summary.riskLevel.color)
    } else {
      StatCard(
        symbol: .wineglassFill,
        title: "Alcohol",
        value: String(localized: "No Data", comment: "Stat card value shown when there is no data"),
        valueStyle: .largeTinted(nil)
      )
      .tint(.secondary)
    }
  }
}

private extension AlcoholStatCard {

  @ViewBuilder
  func barChart(summary: AlcoholSummary) -> some View {
    let maxValue = max(summary.dailyData.map(\.drinks).max() ?? 1, 1)

    GeometryReader { geometry in
      HStack(alignment: .bottom, spacing: 2) {
        ForEach(summary.dailyData) { dayData in
          let height = maxValue > 0 ? (Double(dayData.drinks) / Double(maxValue)) * geometry.size.height : 0

          RoundedRectangle(cornerRadius: 2)
            .fill(summary.riskLevel.color)
            .frame(height: max(height, dayData.drinks > 0 ? 4 : 2))
            .opacity(dayData.drinks > 0 ? 1 : 0.3)
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        AlcoholStatCard(summary: AlcoholSummary(
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
        ))
        AlcoholStatCard(summary: nil)
      }
      HStack {
        AlcoholStatCard(summary: AlcoholSummary(
          weeklyTotal: 18,
          dailyData: [
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-6 * 86400), drinks: 5),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-5 * 86400), drinks: 2),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-4 * 86400), drinks: 0),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-3 * 86400), drinks: 6),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-2 * 86400), drinks: 0),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-1 * 86400), drinks: 3),
            AlcoholSummary.DailyAlcoholData(date: Date(), drinks: 2)
          ],
          bingeDays: 2,
          heavyDays: 0
        ))
        AlcoholStatCard(summary: AlcoholSummary(
          weeklyTotal: 3,
          dailyData: [
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-6 * 86400), drinks: 0),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-5 * 86400), drinks: 1),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-4 * 86400), drinks: 0),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-3 * 86400), drinks: 1),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-2 * 86400), drinks: 0),
            AlcoholSummary.DailyAlcoholData(date: Date().addingTimeInterval(-1 * 86400), drinks: 1),
            AlcoholSummary.DailyAlcoholData(date: Date(), drinks: 0)
          ],
          bingeDays: 0,
          heavyDays: 0
        ))
      }
    }
  }
}
