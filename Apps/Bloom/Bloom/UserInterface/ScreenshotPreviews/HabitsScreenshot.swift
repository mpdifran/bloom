//
//  HabitsScreenshot.swift
//  Bloom
//

import SwiftUI
import AppUI
import BloomUI
import CoreHealth
import DataContainer
import SFSafeSymbols

/// A habit's detail screen, as it appears in the App Store screenshots.
///
/// `GoalGrid` is the app's real grid, fed a fixture model. The surrounding stats are recomposed:
/// `HabitDetailsView` is driven by a view model over a SwiftData `Habit`.
struct HabitsScreenshot: View {
  let fixtures: ScreenshotFixtures

  var body: some View {
    NavigationStack {
      BloomScrollView(spacing: 20, padding: []) {
        VStack(spacing: 4) {
          Text("\(fixtures.steps(fixtures.stepsToday)) steps")
            .font(.system(size: 56, weight: .bold, design: .rounded))
            .foregroundStyle(.tint)
            .minimumScaleFactor(0.5)
            .lineLimit(1)

          HStack {
            Text("Steps")
            Text(verbatim: "•")
            Text("Today")
          }
          .font(.body)
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)
        }
        .padding(.horizontal)

        GoalGrid(model: fixtures.stepGrid)
          .padding(.bottom)

        VStack(spacing: 16) {
          HStack {
            Text("Daily Goal")
              .font(.title2)
              .bold()
            Spacer()
            Text("\(fixtures.steps(fixtures.stepGoal)) steps")
              .font(.title2)
              .bold()
          }
          .fontDesign(.rounded)

          Divider()

          HStack {
            VStack {
              Text(fixtures.worstStepDay)
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
              Text("Worst Day")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .horizontallyCentered()

            Divider()

            VStack {
              Text(fixtures.bestStepDay)
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
              Text("Best Day")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .horizontallyCentered()
          }
        }
        .cardContainer()
        .padding(.horizontal)

        HStack {
          Text("Daily Values")
            .font(.title3)
            .bold()
            .fontDesign(.rounded)

          Spacer()

          Text("AVG")
            .font(.caption2)
            .foregroundStyle(.secondary)

          Text("\(fixtures.steps(fixtures.stepAverage)) steps")
            .font(.headline)
            .fontDesign(.rounded)
        }
        .cardContainer()
        .padding(.horizontal)
      }
      // The grid, the value and the chart all draw from .tint, and the real screen sets it from the
      // habit's metric - green for steps. Without this the host's theme tint bleeds through.
      .tint(TargetMetric.stepCount.color)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button { } label: {
            Image(systemSymbol: .chevronLeft)
          }
          .buttonStyle(.plain)
          .bold()
        }

        ToolbarItem(placement: .principal) {
          Image(systemSymbol: .figureWalk)
            .font(.title3)
            .bold()
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button { } label: {
            Image(systemSymbol: .ellipsis)
          }
          .buttonStyle(.plain)
          .bold()
        }
      }
    }
  }
}

#Preview("Habits - Steps") {
  ScreenshotPreviewHost(selectedTab: .today) { fixtures in
    HabitsScreenshot(fixtures: fixtures)
  }
}
