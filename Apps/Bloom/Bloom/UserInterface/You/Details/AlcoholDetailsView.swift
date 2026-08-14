//
//  AlcoholDetailsView.swift
//  Bloom
//
//  Created by Claude on 2026-01-24.
//

import SwiftUI
import Charts
import HealthKit
import CoreHealth
import TelemetryDeck

struct AlcoholDetailsView: View {
  @ObservedObject private var healthManager = HealthManager.shared

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var alcoholSummary: AlcoholSummary?
  @State private var isLoading = true

  var body: some View {
    BloomScrollView {
      VStack(spacing: 20) {
        StatTimePeriodPicker(selectedPeriod: $selectedPeriod)
          .padding(.horizontal)

        if isLoading {
          ProgressView()
            .padding(.top, 100)
        } else if let summary = alcoholSummary, summary.hasData {
          contentView(summary: summary)
        } else {
          emptyStateView
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Alcohol",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Alcohol")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      TelemetryDeck.viewScreen("Alcohol Details")
    }
    .task(id: selectedPeriod) {
      await loadData()
    }
    .animation(.default, value: selectedPeriod)
  }

  private func loadData() async {
    let interval = selectedPeriod.aggregatesByWeek
      ? DateComponents(weekOfYear: 1)
      : DateComponents(day: 1)
    let summary = await HealthStoreFetcher.shared.fetchAlcoholSummary(
      dateRange: selectedPeriod.dateRange,
      interval: interval,
      sex: healthManager.sexKind
    )
    await MainActor.run {
      withAnimation {
        self.alcoholSummary = summary
        self.isLoading = false
      }
    }
  }
}

private extension AlcoholDetailsView {

  @ViewBuilder
  func contentView(summary: AlcoholSummary) -> some View {
    VStack(spacing: 20) {
      weeklyChartSection(summary: summary)
      riskLevelSection(summary: summary)
      infoSection
    }
  }

  @ViewBuilder
  func weeklyChartSection(summary: AlcoholSummary) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Total")
          .font(.headline)
        Spacer()
        Text(summary.weeklyTotalDisplayString)
          .font(.title2)
          .bold()
          .foregroundStyle(summary.riskLevel.color)
          .contentTransition(.numericText())
      }

      Chart(summary.dailyData) { dayData in
        BarMark(
          x: .value("Day", dayData.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
          y: .value("Drinks", dayData.drinks)
        )
        .foregroundStyle(dayData.color(for: healthManager.sexKind).gradient)
        .cornerRadius(4)
      }
      .chartXAxis {
        AxisMarks(values: .automatic) { _ in
          AxisGridLine()
          AxisValueLabel(format: selectedPeriod.chartDateFormat)
        }
      }
      .chartYAxis {
        AxisMarks { value in
          AxisValueLabel()
          AxisGridLine()
        }
      }
      .frame(height: 200)
      .animation(.default, value: summary.dailyData)
    }
    .cardContainer()
  }

  @ViewBuilder
  func riskLevelSection(summary: AlcoholSummary) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Risk Level")
          .font(.headline)
        Spacer()
        Text(summary.riskLevel.displayName)
          .font(.headline)
          .bold()
          .foregroundStyle(summary.riskLevel.color)
      }

      Divider()

      VStack(alignment: .center, spacing: 8) {
        if summary.bingeDays > 0 {
          VStack {
            Text(verbatim: "\(summary.bingeDays)")
              .font(.system(size: 60, weight: .heavy, design: .rounded))
              .foregroundStyle(summary.riskLevel.color)
              .contentTransition(.numericText(value: Double(summary.bingeDays)))

            Text("Binge drinking day\(summary.bingeDays == 1 ? "" : "s")")
              .font(.subheadline)
          }
        }
        if summary.heavyDays > 0 {
          VStack {
            Text(verbatim: "\(summary.bingeDays)")
              .font(.system(size: 60, weight: .heavy, design: .rounded))
              .foregroundStyle(summary.riskLevel.color)
              .contentTransition(.numericText(value: Double(summary.bingeDays)))

            Text("Heavy drinking day\(summary.heavyDays == 1 ? "" : "s")")
              .font(.subheadline)
          }
        }
        if summary.bingeDays == 0 && summary.heavyDays == 0 {
          VStack {
            Text("No binge or heavy drinking days")
              .font(.subheadline)
          }
        }
      }
      .horizontallyCentered()
      .padding(.vertical, 24)
    }
    .cardContainer()
  }

  var infoSection: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Guidelines")
          .font(.headline)
      }

      Divider()

      VStack(alignment: .leading, spacing: 8) {
        Text("**Low-risk drinking** is defined as:")

        if healthManager.sexKind == .male {
          Text("• No more than 4 drinks on any single day")
          Text("• No more than 14 drinks per week")
        } else {
          Text("• No more than 3 drinks on any single day")
          Text("• No more than 7 drinks per week")
        }

        Text("")
        Text("**Binge drinking** is consuming:")

        if healthManager.sexKind == .male {
          Text("• 5 or more drinks within a few hours")
        } else {
          Text("• 4 or more drinks within a few hours")
        }
      }
      .horizontalAlignment(.leading)
      .foregroundStyle(.secondary)
    }
    .cardContainer()
  }

  var emptyStateView: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemSymbol: .wineglassFill)
        .font(.system(size: 60))
        .foregroundStyle(.secondary)

      VStack(spacing: 8) {
        Text("No Alcohol Data")
          .font(.title2)
          .bold()

        Text("Track your alcohol consumption using the Drinks action card to see your weekly intake here.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer()
    }
    .frame(maxHeight: .infinity)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      AlcoholDetailsView()
    }
  }
}
