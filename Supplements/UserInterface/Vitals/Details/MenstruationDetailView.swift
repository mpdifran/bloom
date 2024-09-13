//
//  MenstruationDetailView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import SwiftUI
import HealthKit
import TelemetryDeck

struct MenstruationDetailView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MenstruationCalendarView(cycles: menstruationSummary?.menstrualCycles ?? [])

                predictedPeriodCell
            }
            .padding()
            .horizontallyCentered()
        }
        .navigationTitle("Cycle Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            TelemetryDeck.viewScreen("Cycle Tracking Vital Details")
        }
    }
}

private extension MenstruationDetailView {

    var menstruationSummary: MenstrualSummary? {
        viewModel.menstrualSummary
    }

    var predictedPeriodCell: some View {
        LabeledContent("Next Period") {
            Group {
                if let predictionDate = menstruationSummary?.nextPredictedPeriodDate {
                    VStack(alignment: .trailing) {
                        Text("\(predictionDate, formatter: DateFormatter.monthAndDay)")
                        Text("\(DateFormatter.relativeTimeIntervalDaysFullFromNow(predictionDate))")
                            .font(.caption)
                    }
                } else {
                    Text("Unsure")
                }
            }
            .foregroundStyle(.mutedPink)
            .font(.title2)
            .bold()
            .fontDesign(.rounded)
        }
        .cardContainer(fill: .background.secondary)
    }
}
