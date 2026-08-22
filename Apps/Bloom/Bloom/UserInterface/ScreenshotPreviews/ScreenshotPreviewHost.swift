//
//  ScreenshotPreviewHost.swift
//  Bloom
//

import SwiftUI
import AppUI
import SFSafeSymbols

/// Hosts a screenshot view inside the app's real tab bar, without preview chrome.
///
/// Deliberately not `PreviewEnvironment`: that overlays a Developer Menu button, which would land
/// in every captured image. This injects only what the real screens read from the environment, and
/// wraps the content in the same `TabView` `RootView` builds so captures include the tab bar.
///
/// ## Capturing another language
///
/// Set the language once, for the whole process - don't pass a locale per preview. Most of the copy
/// on these screens comes from the app's own components, which resolve `String(localized:)` against
/// the bundle's preferred localization rather than the SwiftUI environment. Overriding only
/// `\.locale` would translate the fixture text and leave every button, title and metric name in
/// English.
///
/// In Xcode: Product > Scheme > Edit Scheme > Run > Options > App Language, pick the language, then
/// reopen the canvas. Everything - fixtures, app strings, dates and number formatting - follows.
struct ScreenshotPreviewHost<Content: View>: View {
  /// Which tab appears selected in the captured image.
  let selectedTab: TabKind
  let content: (ScreenshotFixtures) -> Content

  @Bindable private var tabController = TabController()
  @Bindable private var themeController = ThemeController.shared

  init(
    selectedTab: TabKind,
    @ViewBuilder content: @escaping (ScreenshotFixtures) -> Content
  ) {
    self.selectedTab = selectedTab
    self.content = content

    // One injection point for the profile photo, rather than an override on every component that
    // draws it: the toolbar button and the biological age meter both read it from here.
    UserController.shared.profilePhoto = ScreenshotFixtures(locale: .current).avatar
  }

  var body: some View {
    TabView(selection: .constant(selectedTab)) {
      Tab(value: TabKind.today) {
        tabContent(for: .today)
      } label: {
        Label("Today", image: .todayTab)
      }

      Tab(value: TabKind.nutrition) {
        tabContent(for: .nutrition)
      } label: {
        Label("Nutrition", image: .nutritionTab)
      }

      Tab(value: TabKind.you) {
        tabContent(for: .you)
      } label: {
        Label("You", systemSymbol: .figure)
      }

      Tab(value: TabKind.workouts) {
        tabContent(for: .workouts)
      } label: {
        Label("Workouts", image: .workoutsTab)
      }

      // Mirrors RootView: `.prominent` only exists in the iOS 27 SDK, so fall back on older Xcode.
      #if compiler(>=6.4)
      if #available(iOS 27.0, *) {
        Tab("Actions", systemImage: "plus", value: TabKind.actions, role: .prominent) {
          tabContent(for: .actions)
        }
      } else {
        Tab("Actions", systemImage: "plus", value: TabKind.actions, role: .search) {
          tabContent(for: .actions)
        }
      }
      #else
      Tab("Actions", systemImage: "plus", value: TabKind.actions, role: .search) {
        tabContent(for: .actions)
      }
      #endif
    }
    .tint(themeController.theme.color)
    .environment(tabController)
    .environment(themeController)
    .overlay(alignment: .top) { statusBar }
  }

  /// The iPhone 17 Pro status bar, drawn in because the real one never appears in a capture.
  ///
  /// `ScreenshotCaptureTests` renders these views into a window it owns, and the status bar is
  /// system UI drawn outside the app's hierarchy - so captures come out with an empty strip where
  /// it should be. This fills that strip.
  ///
  /// The asset is the real thing at 9:41, cropped so it needs no resampling: its glyphs sit at the
  /// same pixel offsets iOS uses on this device (925x39 at +175+78 in a 1206-wide capture), and at
  /// 3x its 1206x177 pixels are exactly the 402x59pt safe-area inset. Drawn at its natural size,
  /// so any scaling would mean the crop is wrong rather than silently blurring it.
  private var statusBar: some View {
    Image("ScreenshotStatusBar")
      .ignoresSafeArea()
      .allowsHitTesting(false)
  }

  /// Only the selected tab renders content; the others exist purely so the tab bar looks real.
  @ViewBuilder
  private func tabContent(for tab: TabKind) -> some View {
    if tab == selectedTab {
      content(ScreenshotFixtures(locale: .current))
    } else {
      Color.clear
    }
  }
}
