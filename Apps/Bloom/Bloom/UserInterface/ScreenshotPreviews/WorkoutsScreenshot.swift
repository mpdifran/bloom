//
//  WorkoutsScreenshot.swift
//  Bloom
//

import SwiftUI
import AppUI
import BloomUI
import CoreHealth
import SFSafeSymbols

/// The Workouts tab, as it appears in the App Store screenshots.
///
/// `TrainingLoadChartView` is the real chart, fed a fixture summary rather than HealthKit. The plan
/// cards are recomposed: the real ones come from a SwiftData `@Query`.
struct WorkoutsScreenshot: View {
  let fixtures: ScreenshotFixtures

  private var capturedAt: Date {
    DateComponents(
      calendar: Calendar(identifier: .gregorian),
      timeZone: TimeZone(identifier: "America/Toronto"),
      year: 2026, month: 2, day: 7
    ).date ?? .now
  }

  var body: some View {
    NavigationStack {
      BloomScrollView(padding: .vertical) {
        TrainingLoadChartView(summary: fixtures.trainingLoad(endingAt: capturedAt))

        Group {
          Picker("Section", selection: .constant(1)) {
            Text("Workouts").tag(0)
            Text("Plans").tag(1)
          }
          .pickerStyle(.segmented)
          .padding(.top)

          Button { } label: {
            Label("Create A Plan", systemSymbol: .sparkles)
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
          .padding(.top)

          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(fixtures.workoutPlans) { plan in
              planCard(plan)
            }
          }
          .padding(.top)
        }
        .padding(.horizontal)
      }
      .navigationTitle("Workouts")
    }
  }
}

private extension WorkoutsScreenshot {

  func planCard(_ plan: ScreenshotFixtures.WorkoutPlanCard) -> some View {
    VStack(spacing: 8) {
      // The real overlapping activity icons the plan cell draws.
      WorkoutPlanIconView(workoutTypes: plan.workoutTypes)
        .frame(height: 60)

      Text(plan.title)
        .font(.headline)
        .multilineTextAlignment(.center)
        .lineLimit(2)

      Text(plan.duration)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .horizontallyCentered()
    .cardContainer()
  }
}

#Preview("Workouts") {
  ScreenshotPreviewHost(selectedTab: .workouts) { fixtures in
    WorkoutsScreenshot(fixtures: fixtures)
  }
}
