//
//  TodayScreenshot.swift
//  Bloom
//

import SwiftUI
import AppUI
import BloomModel
import BloomUI
import SFSafeSymbols

/// The Today screen as it appears in the App Store screenshots.
///
/// Built from the same cells the real screen uses, fed by `ScreenshotFixtures` instead of the
/// backend, HealthKit and SwiftData. Capture it from the preview canvas: no sign-in, no seeded
/// database, no waiting on an AI response, and every locale is one preview away.
struct TodayScreenshot: View {
  let fixtures: ScreenshotFixtures

  /// Pinned so the greeting says "Good Afternoon" and the date reads the same in every capture.
  private var capturedAt: Date {
    DateComponents(
      calendar: Calendar(identifier: .gregorian),
      timeZone: TimeZone(identifier: "America/Toronto"),
      year: 2026, month: 2, day: 7, hour: 13, minute: 39
    ).date ?? .now
  }

  var body: some View {
    NavigationStack {
      BloomScrollView(padding: .bottom) {
        ZStack {
          // The scenery sits behind the hero, exactly as TodayView layers it. Pinned to afternoon
          // so it matches the greeting rather than following the capture machine's clock.
          Image(.afternoonScenery)
            .resizable()
            .scaledToFit()
            .compositingGroup()
            .drawingGroup()
            .parallaxOverscroll()
            .zStackAlignment(.top)

          VStack(alignment: .leading, spacing: 20) {
            TodayHeroCell(
              budState: .yoga,
              summary: fixtures.todaySummary,
              hasError: false,
              isLoading: false,
              nameOverride: fixtures.firstName,
              dateOverride: capturedAt
            )
            .padding(.horizontal)

            TodaysAdviceTodayCell(advice: fixtures.todaysAdvice)
              .padding(.horizontal)
          }
          .padding(.top, 160)
          // Clears the tab bar. German and French run noticeably longer than English, and without
          // this the advice card is cut off at the bottom of the capture.
          .padding(.bottom, 100)
        }
      }
      // Always hidden, not scroll-driven: the capture is always at the top of the screen, where
      // TodayView suppresses the nav bar's scroll edge blur so the scenery runs behind it.
      .removeScrollEdgeEffect(shouldHide: true)
      .ignoresSafeArea(.all, edges: .top)
      .navigationTitle("Today")
      .navigationBarTitleDisplayMode(.inline)
      // Same toolbar the real Today screen builds, so the captured chrome matches the app.
      .toolbar {
        SettingsProfileViewToolbarButton(photoOverride: fixtures.avatar)

        ToolbarItemGroup(placement: .topBarLeading) {
          Button { } label: {
            Image(systemSymbol: .sliderHorizontal3)
          }
          .buttonStyle(.plain)
          .bold()

          Button { } label: {
            Image(systemSymbol: .trophy)
          }
          .buttonStyle(.plain)
          .bold()
        }
      }
    }
  }
}

#Preview("Today") {
  ScreenshotPreviewHost(selectedTab: .today) { fixtures in
    TodayScreenshot(fixtures: fixtures)
  }
}
