//
//  SleepDayView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

import SwiftUI
import CoreHealth

struct SleepDayView: View {

    @State private var date = Date.now
    @State private var sleepAnalysis: SleepAnalysis?

    @State private var showDatePicker = false
    @State private var lastAppearDate = Date()

    var body: some View {
        Group {
            if let sleepAnalysis {
                List {
                    VStack {
                        SleepScoreView(sleepAnalysis: sleepAnalysis)
                            .frame(maxHeight: 350)

                        SleepScoreDetailsView(sleepAnalysis: sleepAnalysis)
                    }

                    SleepStageChartView(sleepAnalysis: sleepAnalysis)

                    SleepHeartRateSummaryCell(heartRates: sleepAnalysis.heartRate)
                    SleepSoundLevelSummaryCell(soundLevels: sleepAnalysis.environmentalSoundLevels)
                    SleepRespiratoryRateSummaryCell(respiratoryRates: sleepAnalysis.respiratoryRate)
                    if let wristTemperature = sleepAnalysis.wristTemperature {
                        WristTemperatureSummaryCell(wristTemperature: wristTemperature)
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
            if !Calendar.current.isDateInToday(lastAppearDate) {
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
        SleepDayView()
    }
}
