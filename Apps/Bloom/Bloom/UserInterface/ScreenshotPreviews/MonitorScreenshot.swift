//
//  MonitorScreenshot.swift
//  Bloom
//

import SwiftUI
import AppUI
import CoreHealth
import DataContainer
import SFSafeSymbols

/// The Recovery & Sickness monitor detail, as it appears in the App Store screenshots.
///
/// Uses the real chart, insight card and range row; the health database they normally read is
/// replaced by fixtures.
struct MonitorScreenshot: View {
  let fixtures: ScreenshotFixtures

  /// Pinned so the chart's dates are identical in every capture.
  private var capturedAt: Date {
    DateComponents(
      calendar: Calendar(identifier: .gregorian),
      timeZone: TimeZone(identifier: "America/Toronto"),
      year: 2026, month: 2, day: 7
    ).date ?? .now
  }

  var body: some View {
    NavigationStack {
      BloomScrollView(spacing: 20) {
        MonitorStateChart(
          monitorType: .recovery,
          days: 30,
          injectedRanges: fixtures.monitorRanges(endingAt: capturedAt)
        )
        .cardContainer()

        MonitorInsightCard(
          insight: fixtures.monitorInsight,
          suggestion: fixtures.monitorSuggestion,
          isLoading: false,
          reloadInsight: { }
        )

        VStack(alignment: .leading, spacing: 12) {
          Text("30-Day Ranges")
            .font(.headline)

          MetricRangeRow(
            rangeData: fixtures.restingHeartRate,
            metricType: .restingHeartRate
          )
          .cardContainer()
        }
      }
      // Mirrors RecoveryDetailView's toolbar. The back button is drawn explicitly: this view is a
      // navigation root in the preview, so there's nothing for the system to generate one from.
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button { } label: {
            Image(systemSymbol: .chevronLeft)
          }
          .buttonStyle(.plain)
          .bold()
        }

        ToolbarItem(placement: .principal) {
          Text("Recovery & Sickness")
            .font(.headline)
        }

        ToolbarItem(placement: .topBarTrailing) {
          Picker("Time Period", selection: .constant(StatTimePeriod.oneMonth)) {
            Text("7D").tag(StatTimePeriod.sevenDays)
            Text("30D").tag(StatTimePeriod.oneMonth)
          }
          .pickerStyle(.segmented)
          .fixedSize()
        }
        // As in RecoveryDetailView: without this the picker draws inside the toolbar's shared glass
        // background, so the capture shows a capsule around it that the real screen never has.
        .hiddenSharedBackground()
      }
      .navigationTitle("Recovery")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

#Preview("Monitor - Recovery") {
  ScreenshotPreviewHost(selectedTab: .you) { fixtures in
    MonitorScreenshot(fixtures: fixtures)
  }
}
