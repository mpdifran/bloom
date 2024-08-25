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

    @State private var events = [EKEvent]()
    @State private var selectedEvent: EKEvent?

    @State private var showSleepTodayView = false

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            List {
                sleepSection
                calendarSection
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
