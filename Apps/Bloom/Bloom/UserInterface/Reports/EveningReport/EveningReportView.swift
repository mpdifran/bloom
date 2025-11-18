//
//  EveningReportView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SwiftUI
import AppUI
@preconcurrency import EventKit
import EventKitUI
import SwiftData
import DataContainer

@MainActor
struct EveningReportView: View {

    @Environment(\.dismiss) private var dismiss

    @Query var activeHabits: [Habit]

    @State private var selectedHabit: Habit?
    @State private var events = [EKEvent]()
    @State private var selectedEvent: EKEvent?

    @State private var completedTargetMetrics = Set<TargetMetric>()

    @State private var vitalsViewModel = VitalsViewModel.shared

    init() {
        _activeHabits = Query(
            filter: #Predicate<Habit> { habit in
                habit.endDate == nil
            },
            sort: \Habit.startDate,
            order: .reverse
        )
    }

    var body: some View {
        NavigationStack {
            List {
                currentDateSection
                    .removeListSeparator()
                habitsSection
                calendarSection
            }
            .navigationTitle("Evening Report")
            .listStyle(.plain)
            .shelf {
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Done")
                        .horizontallyCentered()
                })
                .buttonStyle(.primary)
            }
            .navigationDestination(item: $selectedHabit) { habit in
                HabitDetailsView(habit: habit)
            }
            .sheet(item: $selectedEvent) { event in
                EKEventView(event: event)
            }
        }
        .presentationCompactAdaptation(.fullScreenCover)
        .tint(.indigo)
        .task {
            self.events = await CalendarManager.shared.eventsTomorrow()
        }
        .task {
            await calculateHabitCompletion()
        }
    }
}

private extension EveningReportView {

    @ViewBuilder
    var currentDateSection: some View {
        TodaysDateView()
    }

    @ViewBuilder
    var habitsSection: some View {
        if activeHabits.isNotEmpty {
            if completedTargetMetrics.isNotEmpty {
                Section("Completed Habits") {
                    ForEach(activeHabits) { habit in
                        if completedTargetMetrics.contains(habit.targetMetric) {
                            Button {
                                selectedHabit = habit
                            } label: {
                                EveningHabitStatusCell(habit: habit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if completedTargetMetrics.count < activeHabits.count {
                Section("To Focus On Tomorrow") {
                    ForEach(activeHabits) { habit in
                        if !completedTargetMetrics.contains(habit.targetMetric) {
                            Button {
                                selectedHabit = habit
                            } label: {
                                EveningHabitStatusCell(habit: habit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    var allDayEvents: [EKEvent] {
        events.filter({ $0.isAllDay })
    }

    var nonAllDayEvents: [EKEvent] {
        events.filter({ !$0.isAllDay })
    }

    var calendarSection: some View {
        Section("Tomorrow's Events") {
            if events.isEmpty {
                Text("No Events")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.secondary)
                    .horizontallyCentered()
                    .frame(height: 100)
                    .standardListSeparatorInset()
            }
            ForEach(allDayEvents) { event in
                AllDayEventCell(event: event)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEvent = event
                    }
            }
            ForEach(nonAllDayEvents) { event in
                EventCell(event: event)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEvent = event
                    }
            }
        }
    }
}

private extension EveningReportView {

    func calculateHabitCompletion() async {
        for habit in activeHabits {
            let targetMetric = habit.targetMetric

            let dailyQuantity = await targetMetric.fetchTotalQuantity(for: .today())

            if habit.quantityMeetsGoal(dailyQuantity) {
                completedTargetMetrics.insert(targetMetric)
            }
        }
    }
}

#Preview {
    NavigationStack {
        EveningReportView()
    }
}
