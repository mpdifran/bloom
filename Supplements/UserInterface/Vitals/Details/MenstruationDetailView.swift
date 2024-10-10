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

    @State private var viewModel = VitalsViewModel.shared

    @State private var selectedPhase: MenstrualCyclePhase?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MenstruationCalendarView(menstruationSummary: menstruationSummary)

                currentStatusSection
                detailsSection
            }
            .padding()
            .horizontallyCentered()
        }
        .navigationTitle("Cycle Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedPhase) { phase in
            CyclePhaseLearnMoreView(phase: phase)
        }
        .onAppear {
            TelemetryDeck.viewScreen("Cycle Tracking Vital Details")
        }
    }
}

private extension MenstruationDetailView {

    var menstruationSummary: MenstrualSummary? {
        viewModel.menstrualSummary
    }

    var currentStatusSection: some View {
        VStack {
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

            Divider()

            LabeledContent("Current Phase") {
                Group {
                    if let phaseDescription = menstruationSummary?.phaseName {
                        Text(phaseDescription)
                            .foregroundStyle(menstruationSummary?.color ?? .mutedPink)
                    } else {
                        Text("Unknown")
                    }
                }
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
            }
        }
        .cardContainer(fill: .background.secondary)
    }

    @ViewBuilder
    var detailsSection: some View {
        if
            let phase = menstruationSummary?.currentPhase(),
            let details = phase.details
        {
            DetailInfoCardView {
                Text(details)

                if phase.coolFacts.isNotEmpty {
                    Button("Learn More") {
                        selectedPhase = phase
                    }
                    .frame(height: 44)
                }
            }
            .tint(.mutedPink)
        }
    }
}

#Preview {
    NavigationStack {
        MenstruationDetailView()
    }
}
