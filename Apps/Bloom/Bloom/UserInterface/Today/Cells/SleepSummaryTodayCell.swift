//
//  SleepSummaryTodayCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import CoreHealth

struct SleepSummaryTodayCell: View {
  let summary: String

  @State private var sleepAnalysis: SleepAnalysis?

  var body: some View {
    VStack {
      if let sleepAnalysis {
        contentView(sleepAnalysis: sleepAnalysis)
      } else {
        noContentView
      }
    }
    .cardContainer()
    .animation(.default, value: sleepAnalysis)
    .task {
      let sleepAnalysis = await HealthStoreFetcher.shared.fetchSleepAnalysis(for: .now)
      await MainActor.run {
        self.sleepAnalysis = sleepAnalysis
      }
    }
  }
}

private extension SleepSummaryTodayCell {

  var noContentView: some View {
    ContentUnavailableView(
      "No Sleep Data",
      systemSymbol: .moonFill,
      description: Text("There is no sleep data for last night.")
    )
  }

  func contentView(sleepAnalysis: SleepAnalysis) -> some View {
    VStack(spacing: 12) {
      if sleepAnalysis.hasDetailedSleepCategories {
        AppleSleepStageChartView(sleepAnalysis: sleepAnalysis)
          .frame(height: 200)

        Divider()
      }

      VStack(alignment: .leading) {
        HStack(alignment: .top) {
          VStack(alignment: .leading) {
            Text(DateFormatter.weekdayFullMonthDayYear.string(from: sleepAnalysis.endDate))
              .font(.title3)

            Text(verbatim: "\(DateFormatter.justTimeShort.string(from: sleepAnalysis.startDate)) - \(DateFormatter.justTimeShort.string(from: sleepAnalysis.endDate))")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .bold()
          .fontDesign(.rounded)

          Spacer()

          MicroSleepScoreView(score: sleepAnalysis.overallScore)
        }
        Text(summary)
          .font(.body)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      SleepSummaryTodayCell(summary: "You done slept good.")
    }
  }
}
