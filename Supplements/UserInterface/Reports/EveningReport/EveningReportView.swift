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

@MainActor
struct EveningReportView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var goalsViewModel = GoalsViewModel.shared

    @State private var events = [EKEvent]()
    @State private var selectedEvent: EKEvent?

    var body: some View {
        NavigationStack {
            List {
                goalsSection
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
                .buttonStyle(.tertiary)
            }
        }
        .tint(.indigo)
        .sheet(item: $selectedEvent) { event in
            EKEventView(event: event)
        }
        .task {
            await CalendarManager.shared.promptForPermission()
            self.events = await CalendarManager.shared.eventsTomorrow()
        }
    }
}

private extension EveningReportView {

    var goalsSection: some View {
        Section("Goals") {
            ForEachEnumeratedNoID(goalsViewModel.goals) { (index, goals) in
                if let goal = goals.first {
                    NavigationLink {
                        GoalDetailsView(goals: $goalsViewModel.goals[index])
                    } label: {
                        EveningGoalProgressCell(goal: goal)
                    }
                    .buttonStyle(.plain)
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

    @ViewBuilder
    var calendarSection: some View {
        if events.isNotEmpty {
            Section("Tomorrow's Events") {
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
}

#Preview {
    NavigationStack {
        EveningReportView()
    }
}
