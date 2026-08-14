//
//  MacroDistributionStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-19.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI
import SFSafeSymbols

struct MacroDistributionStoryPage: View {
  let stats: YearInBloomNutritionStats

  var body: some View {
    VStack {
      macroDistributionChart

      Spacer()

      Image(systemSymbol: .forkKnife)
        .foregroundStyle(.protein)
        .font(.system(size: 50))
        .contentTransition(.symbolEffect)
        .padding(.bottom)

      focusSentence
        .font(.title)
        .fontWeight(.bold)
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()

      statCardsView
    }
    .ignoresSafeArea(edges: [.horizontal, .top])
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("Nutrition")
          .font(.title3)
          .fontDesign(.rounded)
          .bold()
      }
    }
  }

  private var focusSentence: Text {
    // One sentence rather than concatenated pieces: the fragments were untranslatable on their
    // own, and word order differs by language. The styled values interpolate as Text.
    let protein = Text("\(yearlyProteinPercent)%").foregroundStyle(.protein)
    let carbs = Text("\(yearlyCarbsPercent)%").foregroundStyle(.carbohydrates)
    let fat = Text("\(yearlyFatPercent)%").foregroundStyle(.fat)

    return Text(
      "Your diet averaged \(protein) protein, \(carbs) carbs, \(fat) fat.",
      comment: "Year in Bloom macro summary. Placeholders are protein, carbohydrate and fat percentages."
    )
  }
}

// MARK: - Chart

private extension MacroDistributionStoryPage {

  var legendView: some View {
    HStack(spacing: 16) {
      macroLegendItem(color: .protein, label: "Protein")
      macroLegendItem(color: .carbohydrates, label: "Carbs")
      macroLegendItem(color: .fat, label: "Fat")
      Spacer()
    }
    .font(.caption)
    .fontDesign(.rounded)
    .padding(.horizontal)
  }

  func macroLegendItem(color: Color, label: String) -> some View {
    HStack(spacing: 4) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
      Text(label)
        .foregroundStyle(.secondary)
    }
  }

  var macroDistributionChart: some View {
    Chart(macroDataPoints) { dataPoint in
      AreaMark(
        x: .value("Month", dataPoint.date),
        y: .value("Percent", dataPoint.value),
        stacking: .standard
      )
      .foregroundStyle(by: .value("Macro", dataPoint.macro.rawValue))
      .interpolationMethod(.catmullRom)
    }
    .chartForegroundStyleScale([
      Macro.protein.rawValue: Color.protein,
      Macro.carbs.rawValue: Color.carbohydrates,
      Macro.fat.rawValue: Color.fat
    ])
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartXScale(domain: yearStart...yearEnd)
    .chartYScale(domain: 0...100)
    .chartLegend(.hidden)
    .frame(height: 360)
  }
}

// MARK: - Stat Cards

private extension MacroDistributionStoryPage {

  var statCardsView: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      // Avg Protein
      HStack {
        Image(systemSymbol: .forkKnife)
          .foregroundStyle(.protein)
          .font(.title2)
        VStack(alignment: .leading, spacing: 0) {
          Text("\(Int(stats.yearTotals.averageProteinGrams))g")
            .font(.title2)
            .bold()
          Text("Avg Protein")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      .cardContainer(fill: .background.secondary)

      // Avg Carbs
      HStack {
        Image(systemSymbol: .leafFill)
          .foregroundStyle(.carbohydrates)
          .font(.title2)
        VStack(alignment: .leading, spacing: 0) {
          Text("\(Int(stats.yearTotals.averageCarbsGrams))g")
            .font(.title2)
            .bold()
          Text("Avg Carbs")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      .cardContainer(fill: .background.secondary)

      // Avg Fat
      HStack {
        Image(systemSymbol: .dropFill)
          .foregroundStyle(.fat)
          .font(.title2)
        VStack(alignment: .leading, spacing: 0) {
          Text("\(Int(stats.yearTotals.averageFatGrams))g")
            .font(.title2)
            .bold()
          Text("Avg Fat")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      .cardContainer(fill: .background.secondary)

      // Days Logged
      HStack {
        Image(systemSymbol: .calendarBadgeClock)
          .foregroundStyle(.secondary)
          .font(.title2)
        VStack(alignment: .leading, spacing: 0) {
          Text("\(stats.yearTotals.totalDaysLogged)")
            .font(.title2)
            .bold()
          Text("Days Logged")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      .cardContainer(fill: .background.secondary)
    }
    .fontDesign(.rounded)
    .padding(.horizontal)
  }
}

// MARK: - Helpers

private extension MacroDistributionStoryPage {

  enum Macro: String {
    case protein = "Protein"
    case carbs = "Carbs"
    case fat = "Fat"
  }

  struct MacroDataPoint: Identifiable {
    var id: String { "\(date.timeIntervalSince1970)-\(macro.rawValue)" }
    let date: Date
    let macro: Macro
    let value: Double
  }

  var macroDataPoints: [MacroDataPoint] {
    stats.monthlyMacroChartData().flatMap { month in
      [
        MacroDataPoint(date: month.date, macro: .protein, value: month.proteinPercent * 100),
        MacroDataPoint(date: month.date, macro: .carbs, value: month.carbsPercent * 100),
        MacroDataPoint(date: month.date, macro: .fat, value: month.fatPercent * 100)
      ]
    }
  }

  var yearStart: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 1, day: 15))!
  }

  var yearEnd: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 12, day: 15))!
  }

  var yearlyProteinPercent: Int {
    Int(stats.yearTotals.proteinPercent * 100)
  }

  var yearlyCarbsPercent: Int {
    Int(stats.yearTotals.carbsPercent * 100)
  }

  var yearlyFatPercent: Int {
    Int(stats.yearTotals.fatPercent * 100)
  }

}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      MacroDistributionStoryPage(stats: .preview)
    }
  }
}
