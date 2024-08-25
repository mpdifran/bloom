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

    @State private var events = [EKEvent]()
    @State private var selectedEvent: EKEvent?

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            List {
                calendarSection
            }
            .navigationTitle("Good Morning")
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
        .sheet(item: $selectedEvent) { event in
            EKEventView(event: event)
        }
        .presentationCompactAdaptation(.fullScreenCover)
        .tint(.blue)
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

    var calendarSection: some View {
        Section("Today") {
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

#Preview {
    GoodMorningView()
}
