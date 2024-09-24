//
//  EveningReportView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SwiftUI
import AppUI
import EventKit
import EventKitUI
import SwiftData
import DataContainer

@MainActor
struct EveningReportView: View {

    @Environment(\.dismiss) private var dismiss

    @Query var suggestedHabits: [Habit]

    @State private var selectedHabit: Habit?
    @State private var events = [EKEvent]()
    @State private var selectedEvent: EKEvent?

    init() {
        _suggestedHabits = Query(
            filter: #Predicate<Habit> { habit in
                habit.endDate == nil && habit.isSuggested
            },
            sort: \Habit.startDate,
            order: .reverse
        )
    }

    var body: some View {
        NavigationStack {
            List {
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
        .tint(.indigo)
        .task {
            await CalendarManager.shared.promptForPermission()
            self.events = await CalendarManager.shared.eventsTomorrow()
        }
    }
}

private extension EveningReportView {

    @ViewBuilder
    var habitsSection: some View {
        if suggestedHabits.isNotEmpty {
            Section("Focus Areas") {
                VStack {
                    ForEach(suggestedHabits) { habit in
                        Button {
                            selectedHabit = habit
                        } label: {
                            EveningHabitProgressCell(habit: habit)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .removeListSeparator()
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

#Preview {
    NavigationStack {
        EveningReportView()
    }
}
