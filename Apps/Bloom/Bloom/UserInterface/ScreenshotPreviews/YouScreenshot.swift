//
//  YouScreenshot.swift
//  Bloom
//

import SwiftUI
import AppUI
import BloomFoundation
import BloomUI
import CoreHealth
import SFSafeSymbols

/// The You screen's biological age header, as it appears in the App Store screenshots.
///
/// Recomposed from `BiologicalAgeMeter` and the header's text rather than reusing `YouHeaderView`:
/// that view reads `HealthManager.shared` and `BiologicalAgeViewModel.shared` directly, which a
/// preview has no way to populate.
struct YouScreenshot: View {
  let fixtures: ScreenshotFixtures

  private var capturedAt: Date {
    DateComponents(
      calendar: Calendar(identifier: .gregorian),
      timeZone: TimeZone(identifier: "America/Toronto"),
      year: 2026, month: 2, day: 7, hour: 13, minute: 34
    ).date ?? .now
  }

  private var result: BiologicalAgeResult {
    BiologicalAgeResult(
      biologicalAge: fixtures.biologicalAge,
      actualAge: fixtures.chronologicalAge,
      // Relative to now, not to the pinned capture date: this renders as "2 hours ago", and
      // anchoring it to February would read as "6 months ago" by the time it was captured.
      lastCalculated: Date().addingTimeInterval(-2 * 60 * 60),
      metricContributions: fixtures.metricContributions
    )
  }

  var body: some View {
    NavigationStack {
      BloomScrollView(spacing: 20) {
        HStack {
          BiologicalAgeMeter(
            chronologicalAge: fixtures.chronologicalAge,
            biologicalAge: fixtures.biologicalAge,
            centerContentKind: .profileImage
          )
          .frame(square: 150)

          VStack(alignment: .leading) {
            Text(fixtures.firstName)
              .font(.largeTitle)
              .bold()
              .fontDesign(.rounded)

            Text("Bio Age: \(fixtures.biologicalAge.format(using: .oneDecimalPlace)) \(Image(systemSymbol: .chevronForward))")
              .font(.title3)
              .bold()
              .fontDesign(.rounded)

            BioAgeConfidenceCardMini(result: result)

            Text("Calculated \(result.lastCalculated, format: .relative(presentation: .named))")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer(minLength: 0)
        }

        // The real section, fed fixtures instead of HealthKit.
        SleepQualitySection(
          presentedNavigationDestination: .constant(nil),
          bedtimeData: fixtures.bedtimeData(endingAt: capturedAt),
          sleepDurationChartData: fixtures.sleepDurationData,
          averageSleepScore: fixtures.averageSleepScore,
          sleepStageDataPoints: fixtures.sleepStages(endingAt: capturedAt),
          averageSleepHeartRate: nil,
          sleepHeartRateChartData: nil,
          sleepRespiratoryRateTrend: nil,
          sleepRespiratoryRateChartData: nil,
          wristTempData: nil
        )
      }
      .navigationTitle("You")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        SettingsProfileViewToolbarButton()

        ToolbarItem(placement: .topBarLeading) {
          Button { } label: {
            Image(systemSymbol: .sliderHorizontal3)
          }
          .buttonStyle(.plain)
          .bold()
        }
      }
    }
  }
}

#Preview("You - Bio Age") {
  ScreenshotPreviewHost(selectedTab: .you) { fixtures in
    YouScreenshot(fixtures: fixtures)
  }
}
