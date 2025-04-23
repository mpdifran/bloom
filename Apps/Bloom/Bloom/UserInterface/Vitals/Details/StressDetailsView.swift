//
//  StressDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-08.
//

import SwiftUI
import Charts
import TelemetryDeck

extension StressDetailsView {
  enum StressContributor: CaseIterable, Hashable {
    case all
    case bloodPressure
    case heartRateVariability
    case sleep

    var name: String {
      switch self {
      case .all: "All"
      case .bloodPressure: "Blood Pressure"
      case .heartRateVariability: "Heart Rate Variability"
      case .sleep: "Sleep"
      }
    }
  }
}

struct StressDetailsView: View {

  private let viewModel = VitalsViewModel.shared

  @State private var selectedContributor: StressContributor = .all

  var body: some View {
    Group {
      if viewModel.stressSummary?.hasNoData == false {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Stress Levels",
          subtitle: "Last 30 Days"
        )
      }
    }
    .animation(.easeInOut, value: selectedContributor)
    .navigationTitle("Stress Levels")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      TelemetryDeck.viewScreen("Stress Vital Details")
    }
  }
}

private extension StressDetailsView {

  var contentView: some View {
    BloomScrollView(spacing: 20) {
      stressLevelChart

      if
        let systolic = viewModel.stressSummary?.details.averageSystolic,
        let diastloic = viewModel.stressSummary?.details.averageDiastolic
      {
        BloodPressureStatusView(
          systolic: systolic,
          diastolic: diastloic,
          lastMonthSystolic: viewModel.stressSummary?.lastMonthAverageSystolic,
          lastMonthDiastolic: viewModel.stressSummary?.lastMonthAverageDiastolic
        )
      }

      heartRateVariabilityChart

      sleepChart
    }
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Data Available",
      systemImage: "bolt.fill",
      description: Text("Wear your Apple Watch throughout the day to get a better picture of your Stress Levels.")
    )
  }

  var stressLevelChart: some View {
    VStack(alignment: .leading) {
      VStack {
        if let averageStressLevelName {
          VitalDetailChartTitleView(
            title: "Daily Stress Levels",
            value: averageStressLevelName
          )
        } else {
          VitalDetailChartTitleView(
            title: "Daily Stress Levels",
            valueLabel: "",
            value: ""
          )
        }

        Chart {
          ForEach(viewModel.stressSummary?.details.stressLevels ?? []) { stressLevel in
            switch selectedContributor {
            case .all:
              BarMark(
                x: .value("Date", stressLevel.date, unit: .day),
                y: .value("Stress Level", stressLevel.stressScore)
              )
              .foregroundStyle(stressLevel.level.color)
            case .bloodPressure:
              BarMark(
                x: .value("Date", stressLevel.date, unit: .day),
                y: .value("Stress Level", stressLevel.bloodPressureStressScore)
              )
              .foregroundStyle(stressLevel.bloodPressureLevel.color)
            case .heartRateVariability:
              BarMark(
                x: .value("Date", stressLevel.date, unit: .day),
                y: .value("Stress Level", stressLevel.hrvStressScore)
              )
              .foregroundStyle(stressLevel.hrvLevel.color)
            case .sleep:
              BarMark(
                x: .value("Date", stressLevel.date, unit: .day),
                y: .value("Stress Level", stressLevel.sleepStressScore)
              )
              .foregroundStyle(stressLevel.sleepLevel.color)
            }
          }
        }
        .chartYScale(
          domain: -1...1,
          range: .plotDimension(padding: 10)
        )
        .chartForegroundStyleScale([
          StressMonthlySummary.Level.relaxed.name: StressMonthlySummary.Level.relaxed.color,
          StressMonthlySummary.Level.mild.name: StressMonthlySummary.Level.mild.color,
          StressMonthlySummary.Level.moderate.name: StressMonthlySummary.Level.moderate.color,
          StressMonthlySummary.Level.high.name: StressMonthlySummary.Level.high.color
        ])
        .frame(height: 260)

        stressContributorPicker
      }
      .cardContainer()

      DetailInfoCardView {
        Text("Your stress level can fluctuate day to day. It's normal to have some days of high stress, but prolonged stress can be harmful to your overall health. Bloom factors in your blood pressure, sleep, and heart rate variability when calculating your stress level.")
      }
      .padding(.top)
    }
  }

  var averageStressLevelName: String? {
    guard let selectedStressLevelScore else { return nil }

    return StressMonthlySummary.Level(score: selectedStressLevelScore).name
  }

  var details: StressMonthlySummary.Details? {
    viewModel.stressSummary?.details
  }

  var stressLevels: [StressMonthlySummary.DateStressScore] {
    details?.stressLevels ?? []
  }

  var selectedStressLevelScore: Double? {
    switch selectedContributor {
    case .all: details?.averageStressLevel
    case .bloodPressure: details?.averageBloodPressureStressLevel
    case .heartRateVariability: details?.averageHeartRateVariabilityStressLevel
    case .sleep: details?.averageSleepStressLevel
    }
  }

  var stressContributorPicker: some View {
    Button {
      guard let index = StressContributor.allCases.firstIndex(of: selectedContributor) else {
        selectedContributor = .all
        return
      }
      let newIndex = (index + 1) % StressContributor.allCases.count
      selectedContributor = StressContributor.allCases[newIndex]
    } label: {
      HStack {
        Text("Contributor")

        Spacer()

        Text(selectedContributor.name)
      }
    }
    .buttonStyle(.zone)
    .tint(pickerTintColor)
    .sensoryFeedback(.selection, trigger: selectedContributor)
  }

  var pickerTintColor: Color {
    guard let selectedStressLevelScore else { return .gray }

    return StressMonthlySummary.Level(score: selectedStressLevelScore).color
  }
}

private extension StressDetailsView {

  var sleepChart: some View {
    VStack(alignment: .leading) {
      VStack {
        if let averageScore = viewModel.stressSummary?.details.averageSleepScore?.format(using: .oneDecimalPlace) {
          VitalDetailChartTitleView(
            title: "Sleep",
            value: "\(averageScore)"
          )
        } else {
          VitalDetailChartTitleView(
            title: "Sleep",
            valueLabel: "",
            value: ""
          )
        }

        Chart {
          ForEach(viewModel.stressSummary?.details.sleepAnalyses ?? []) { sleepAnalysis in
            AreaMark(
              x: .value("Date", sleepAnalysis.endDate),
              y: .value("Sleep Score", sleepAnalysis.overallScoreDouble)
            )
            .foregroundStyle(
              LinearGradient(
                colors: [.remSleep, .clear],
                startPoint: .top,
                endPoint: .bottom
              )
            )

            LineMark(
              x: .value("Date", sleepAnalysis.endDate),
              y: .value("Sleep Score", sleepAnalysis.overallScoreDouble)
            )
            .foregroundStyle(.remSleep)

            PointMark(
              x: .value("Date", sleepAnalysis.endDate),
              y: .value("Sleep Score", sleepAnalysis.overallScoreDouble)
            )
            .foregroundStyle(.remSleep)
          }
        }
        .frame(height: 160)
      }
      .cardContainer()

      DetailInfoCardView {
        Text("A poor sleep can have a negative effect on your stress level for the following day. Try to get enough sleep each night to help keep your stress levels low.")
      }
    }
  }

  var heartRateVariabilityChart: some View {
    VStack(alignment: .leading) {
      VStack {
        if let hrv = viewModel.stressSummary?.details.averageHeartRateVariability?.format() {
          VitalDetailChartTitleView(
            title: "Heart Rate Variability",
            value: "\(hrv) ms"
          )
        } else {
          VitalDetailChartTitleView(
            title: "Heart Rate Variability",
            valueLabel: "",
            value: ""
          )
        }

        Chart {
          ForEach(viewModel.stressSummary?.details.heartRateVariability ?? []) { sample in
            LineMark(
              x: .value("Date", sample.date),
              y: .value("Heart Rate Variability", sample.quantity.doubleValue(for: .millisecond()))
            )
            .foregroundStyle(.mutedRed)
          }

          if let hrv = viewModel.stressSummary?.details.averageHeartRateVariability {
            RuleMark(y: .value("Average HRV", hrv))
              .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
              .foregroundStyle(.mutedRed)
          }
        }
        .frame(height: 160)
      }
      .cardContainer()

      DetailInfoCardView {
        Text("Heart Rate Variability is a measure of how quickly you can change your heart rate. A higher value indicates lower stress and more relaxation, and a lower value indicates your body is in stress.")
      }
    }
  }
}

#Preview {
  NavigationStack {
    StressDetailsView()
  }
}
