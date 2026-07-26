//
//  SleepDayView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

import SwiftUI
import CoreHealth

struct SleepDayView: View {

  let initialDate: Date?

  @State private var date = Date.now

  init(initialDate: Date? = nil) {
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
        BloomScrollView {
          VStack(spacing: 16) {
            AppleSleepStageChartView(sleepAnalysis: sleepAnalysis)
              .frame(height: 200)
              .cardContainer()

            HStack {
              Text("Sleep Score")
                .font(.headline)
                .fontDesign(.rounded)
                .bold()

              Spacer()

              SleepScoreView(score: sleepAnalysis.overallScore, isMini: true)
            }
            .cardContainer()

            SleepScoreDetailsView(sleepAnalysis: sleepAnalysis)

            SleepHeartRateSummaryCell(heartRates: sleepAnalysis.heartRate)
            SleepSoundLevelSummaryCell(soundLevels: sleepAnalysis.environmentalSoundLevels)
            SleepRespiratoryRateSummaryCell(respiratoryRates: sleepAnalysis.respiratoryRate)

            if let wristTemperature = sleepAnalysis.wristTemperature {
              WristTemperatureSummaryCell(wristTemperature: wristTemperature)
            }
          }
        }
        .animation(.default, value: sleepAnalysis)
      } else {
        ContentUnavailableView(
          "No Data Available",
          systemSymbol: .moonZzzFill,
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
  PreviewEnvironment {
    SleepDayView()
  }
}
