//
//  TodayView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

import SwiftUI

struct TodayView: View {
    @State private var showDatePicker = false
    @State private var lastAppearDate = Date()

    @ObservedObject private var viewModel = TodayViewModel.shared

    private let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

    var body: some View {
        NavigationStack {
            Group {
                if let sleepAnalysis = viewModel.sleepAnalysis {
                    List {
                        VStack {
                            SleepScoreView(sleepAnalysis: sleepAnalysis)
                            
                            SleepScoreDetailsView(sleepAnalysis: sleepAnalysis)
                        }

                        SleepStageChartView(sleepAnalysis: sleepAnalysis)

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
        .onReceive(foregroundPublisher) { _ in
            if !Calendar.current.isDateInToday(lastAppearDate) {
                viewModel.date = Date()
            }
            lastAppearDate = Date()
            print("Updated lastAppearDate")
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
