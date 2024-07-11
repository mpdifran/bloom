//
//  TodayView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

import SwiftUI

struct TodayView: View {
    @State private var showDatePicker = false

    @ObservedObject private var viewModel = TodayViewModel.shared

    var body: some View {
        NavigationStack {
            Group {
                if let sleepAnalysis = viewModel.sleepAnalysis {
                    List {
                        SleepScoreView(sleepAnalysis: sleepAnalysis)

//                        SleepStageChartView(sleepAnalysis: sleepAnalysis)

                        SleepHeartRateSummaryCell(heartRates: sleepAnalysis.heartRate)
                        SleepSoundLevelSummaryCell(soundLevels: sleepAnalysis.environmentalSoundLevels)
                        SleepRespiratoryRateSummaryCell(respiratoryRates: sleepAnalysis.respiratoryRate)
                        WristTemperatureSummaryCell(wristTemperature: sleepAnalysis.wristTemperature)
                    }
                    .listStyle(.plain)
                } else {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "moon.zzz",
                        description: Text("There is no sleep analysis available for \(viewModel.date, formatter: DateFormatter.justRelativeDateMedium).")
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TitleDatePicker(date: $viewModel.date)
                }
            }
        }
        .tabItem {
            Label("Sleep", systemImage: "moon.zzz")
        }
    }
}

#Preview {
    TabView {
        TodayView()
    }
}
