//
//  SleepDayView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

import SwiftUI
import CoreHealth

struct SleepDayView: View {

  let showsChatBar: Bool
  let initialDate: Date?

  @State private var date = Date.now

  init(showsChatBar: Bool, initialDate: Date? = nil) {
    self.showsChatBar = showsChatBar
    self.initialDate = initialDate
    if let initialDate {
      _date = State(initialValue: initialDate)
    }
  }
  @State private var sleepAnalysis: SleepAnalysis?

  @State private var showDatePicker = false
  @State private var lastAppearDate = Date()

  var body: some View {
    Group {
      if let sleepAnalysis {
        BloomScrollView(showsChatBar: showsChatBar) {
          VStack {
            SleepScoreView(sleepAnalysis: sleepAnalysis)
              .frame(maxHeight: 350)

            SleepScoreDetailsView(sleepAnalysis: sleepAnalysis)
          }
          .cardContainer()

          SleepStageChartView(sleepAnalysis: sleepAnalysis)
            .cardContainer()

          SleepHeartRateSummaryCell(heartRates: sleepAnalysis.heartRate)
            .cardContainer()
          SleepSoundLevelSummaryCell(soundLevels: sleepAnalysis.environmentalSoundLevels)
            .cardContainer()
          SleepRespiratoryRateSummaryCell(respiratoryRates: sleepAnalysis.respiratoryRate)
            .cardContainer()
          if let wristTemperature = sleepAnalysis.wristTemperature {
            WristTemperatureSummaryCell(wristTemperature: wristTemperature)
              .cardContainer()
          }
        }
        .listStyle(.plain)
      } else {
        ContentUnavailableView(
          "No Data Available",
          systemImage: "moon.zzz",
          description: Text("There is no sleep analysis available for \(date, formatter: DateFormatter.justRelativeDateMedium).")
        )
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: date) { oldValue, newValue in
      Task {
        await fetchNewSleepAnalysis()
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        TitleDatePicker(date: $date)
      }
    }
    .task {
      await fetchNewSleepAnalysis()
    }
    .onAppear {
      // Only reset to today if no initial date was provided and it's a new day
      if initialDate == nil && !Calendar.current.isDateInToday(lastAppearDate) {
        date = Date()
      }
      lastAppearDate = Date()
    }
  }
}

private extension SleepDayView {

  func fetchNewSleepAnalysis() async {
    let sleepAnalysis = await HealthStoreFetcher.shared.fetchSleepAnalysis(for: date)

    await MainActor.run {
      self.sleepAnalysis = sleepAnalysis
    }
  }
}

#Preview {
  TabView {
    SleepDayView(showsChatBar: false)
  }
}
