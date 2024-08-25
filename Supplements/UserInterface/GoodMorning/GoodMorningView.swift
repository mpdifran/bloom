//
//  GoodMorningView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-12.
//

import SwiftUI
import AppUI
import AppFoundations
import EventKit
import EventKitUI

@MainActor
struct GoodMorningView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var healthManager = HealthManager.shared
    @ObservedObject private var vitalsViewModel = VitalsViewModel.shared

    @State private var events = [EKEvent]()
    @State private var selectedEvent: EKEvent?

    @State private var showSleepTodayView = false

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            List {
                sleepSection
                calendarSection
                activityLevelSection
            }
            .navigationTitle("Morning Report")
            .listStyle(.plain)
            .shelf {
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Done")
                        .horizontallyCentered()
                })
                .buttonStyle(.tertiary)
            }
            .navigationDestination(isPresented: $showSleepTodayView) {
                TodayView()
            }
        }
        .sheet(item: $selectedEvent) { event in
            EKEventView(event: event)
        }
        .presentationCompactAdaptation(.fullScreenCover)
        .tint(.blue)
        .animation(.default, value: healthManager.sleepAnalysis7Days)
        .animation(.default, value: events.count)
        .onAppear {
            feedbackGenerator.prepare()
        }
        .task {
            await CalendarManager.shared.promptForPermission()
            self.events = await CalendarManager.shared.eventsToday()
        }
    }
}

private extension GoodMorningView {

    @ViewBuilder
    var sleepSection: some View {
        if let sleepAnalysis = healthManager.sleepAnalysis7Days?.last, Calendar.current.isDateInToday(sleepAnalysis.endDate) {
            Section {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("Sleep Score")
                            .font(.title3)
                            .bold()

                        Text(sleepAnalysis.sleepSummaryDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 0)

                    SleepScoreView(sleepAnalysis: sleepAnalysis, isMini: true)
                }
                .cardContainer(fill: .background.secondary)
                .contentShape(Rectangle())
                .onTapGesture {
                    showSleepTodayView = true
                }
                .removeListSeparator()
            }
        }
    }

    @ViewBuilder
    var activityLevelSection: some View {
        if
            let energyRatioSample = vitalsViewModel.activityLevelSummary?.energyRatioSamples.last(where: { Calendar.current.isDateInYesterday($0.date) })
        {
            switch ActivityLevelSummary.ActivityLevel(energyRatioSample.quantity) {
            case .intense:
                Section("Activity Level") {
                    HStack {
                        Image(systemName: VitalModel.Kind.activityLevel.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                            .frame(width: 50)

                        VStack(alignment: .leading) {
                            Text("Energy Ratio")
                                .font(.title3)
                                .bold()

                            Text("Your Energy Ratio yesterday was in the Intense level (\(energyRatioSample.quantity.format(to: 1))). Make sure to take a break from activity today to give your body time to recover.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            case .sedentary:
                Section("Activity Level") {
                    HStack {
                        Image(systemName: VitalModel.Kind.activityLevel.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                            .frame(width: 50)

                        VStack(alignment: .leading) {
                            Text("Energy Ratio")
                                .font(.title3)
                                .bold()

                            Text("Your Energy Ratio yesterday was in the Sedentary level (\(energyRatioSample.quantity.format(to: 1))). Today might be a good day to get active!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    var calendarSection: some View {
        if events.isNotEmpty {
            Section("Today's Events") {
                ForEach(events) { event in
                    EventCell(event: event)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEvent = event
                        }
                }
            }
        }
    }
}

#Preview {
    GoodMorningView()
}
