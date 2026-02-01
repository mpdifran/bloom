//
//  WorkoutWidget.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-02-01.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct WorkoutTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> WorkoutEntry {
    WorkoutEntry(date: .now)
  }

  func getSnapshot(in context: Context, completion: @escaping (WorkoutEntry) -> Void) {
    completion(WorkoutEntry(date: .now))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutEntry>) -> Void) {
    // Static widget - never needs to refresh
    let timeline = Timeline(entries: [WorkoutEntry(date: .now)], policy: .never)
    completion(timeline)
  }
}

// MARK: - Timeline Entry

struct WorkoutEntry: TimelineEntry {
  let date: Date
}

// MARK: - Widget

struct WorkoutWidget: Widget {
  let kind = "WorkoutWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WorkoutTimelineProvider()) { _ in
      WorkoutWidgetView()
        .containerBackground(.background.secondary, for: .widget)
        .widgetURL(URL(string: "bloom://watch/workouts"))
    }
    .configurationDisplayName("Start Workout")
    .description("Quickly open your workouts.")
    .supportedFamilies([.accessoryCircular])
  }
}

// MARK: - Widget View

struct WorkoutWidgetView: View {
  var body: some View {
    Circle()
      .fill(.background)
      .overlay {
        Image(systemName: "figure.run")
          .font(.system(size: 30))
          .foregroundStyle(.blue.gradient)
      }
  }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
  WorkoutWidget()
} timeline: {
  WorkoutEntry(date: .now)
}
