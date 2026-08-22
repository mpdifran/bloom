//
//  ScreenshotCaptureTests.swift
//  BloomTests
//

import XCTest
import SwiftUI
@testable import Bloom

/// Renders the App Store screenshot views to PNGs on disk.
///
/// A unit test rather than a UI test: there's no app to drive, no navigation to wait on, and no
/// flakiness - each screen is hosted directly and rendered. Xcode's preview canvas can't be
/// scripted, so this renders the same views the previews show.
///
/// Run it through `Apps/Bloom/Scripts/capture-screenshots.sh`, which sweeps the languages.
///
/// The status bar is system UI drawn outside the app's view hierarchy, so it never appears in a
/// capture. `ScreenshotPreviewHost` draws it back in from an asset - see the note there.
///
/// The home indicator and the keyboard are still missing, for the same reason and with no such
/// workaround. The chat screen is captured here without its keyboard; if that shot needs one, take
/// it from a booted simulator instead.
@MainActor
final class ScreenshotCaptureTests: XCTestCase {

  /// iPhone 17 Pro, in points. Rendered at 3x for the pixel dimensions.
  private let size = CGSize(width: 402, height: 874)
  private let scale: CGFloat = 3

  func testCaptureScreenshots() throws {
    let outputDirectory = try outputDirectory()

    try capture(name: "01-today", view: ScreenshotPreviewHost(selectedTab: .today) {
      TodayScreenshot(fixtures: $0)
    }, into: outputDirectory)

    try capture(name: "02-you", view: ScreenshotPreviewHost(selectedTab: .you) {
      YouScreenshot(fixtures: $0)
    }, into: outputDirectory)

    try capture(name: "03-monitor", view: ScreenshotPreviewHost(selectedTab: .you) {
      MonitorScreenshot(fixtures: $0)
    }, into: outputDirectory)

    try capture(name: "04-chat", view: ScreenshotPreviewHost(selectedTab: .today) {
      ChatScreenshot(fixtures: $0)
    }, into: outputDirectory)

    try capture(name: "05-habits", view: ScreenshotPreviewHost(selectedTab: .today) {
      HabitsScreenshot(fixtures: $0)
    }, into: outputDirectory)

    try capture(name: "06-nutrition", view: ScreenshotPreviewHost(selectedTab: .nutrition) {
      NutritionScreenshot(fixtures: $0)
    }, into: outputDirectory)

    try capture(name: "07-workouts", view: ScreenshotPreviewHost(selectedTab: .workouts) {
      WorkoutsScreenshot(fixtures: $0)
    }, into: outputDirectory)

    print("Screenshots written to \(outputDirectory.path)")
  }
}

private enum ScreenshotError: Error {
  case noHostPath
}

private extension ScreenshotCaptureTests {

  /// `<SCREENSHOT_OUTPUT_DIR>/<language>`, defaulting to the Desktop of the Mac that built this.
  ///
  /// The base path is derived from `#filePath` rather than `~`: tests run inside a simulator - often
  /// an ephemeral clone - where `~` resolves to that simulator's container, so anything written
  /// there disappears with the clone. `#filePath` is baked in at compile time and always points at
  /// the host.
  ///
  /// The language comes from the bundle rather than a parameter: the test plan and the capture
  /// script force it per run, and it's what the app's `String(localized:)` resolves against - so the
  /// folder name and the rendered copy can't disagree.
  func outputDirectory() throws -> URL {
    let base: String

    if let configured = ProcessInfo.processInfo.environment["SCREENSHOT_OUTPUT_DIR"] {
      base = configured
    } else {
      // Stage inside the repository rather than on the Desktop.
      //
      // xcodebuild does not forward TEST_RUNNER_ environment variables into a unit test hosted in
      // the app process - that mechanism is for UI test runners - so this fallback is what actually
      // runs, whatever the caller passed. Pointing it at a folder of finished screenshots means any
      // single-language run quietly overwrites the other languages' work, which is exactly what it
      // did. `capture-screenshots.sh` moves the files out of here to wherever it was asked to put
      // them.
      //
      // .../Bloom/Apps/Bloom/BloomTests/Screenshots/ScreenshotCaptureTests.swift -> .../Bloom
      let repository = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Screenshots
        .deletingLastPathComponent()  // BloomTests
        .deletingLastPathComponent()  // Bloom
        .deletingLastPathComponent()  // Apps
        .deletingLastPathComponent()  // repository root

      guard repository.pathComponents.count > 1 else { throw ScreenshotError.noHostPath }

      base = repository.appendingPathComponent(".screenshots").path
    }

    let language = Bundle.main.preferredLocalizations.first ?? "en"
    let directory = URL(fileURLWithPath: base).appendingPathComponent(language)

    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  func capture(name: String, view: some View, into directory: URL) throws {
    let controller = UIHostingController(rootView: view)
    controller.view.frame = CGRect(origin: .zero, size: size)
    controller.view.backgroundColor = .systemBackground

    // Hosting in a real window, not just rendering the view: navigation bars, tab bars and
    // safe-area insets only lay out correctly inside one.
    let window = UIWindow(frame: CGRect(origin: .zero, size: size))

    // The window must belong to the app's scene. An unattached window has nothing to draw into, and
    // `drawHierarchy` on one silently produces a blank image rather than failing.
    window.windowScene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first

    window.rootViewController = controller
    window.makeKeyAndVisible()

    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()

    // Let async content (charts, images, async fixtures) settle before snapshotting.
    RunLoop.current.run(until: Date().addingTimeInterval(1.0))

    let format = UIGraphicsImageRendererFormat()
    format.scale = scale

    let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
      if !window.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true) {
        // Fallback for when the window can't render itself - misses some visual effects, but the
        // content is there, which beats a blank page.
        window.layer.render(in: context.cgContext)
      }
    }

    guard let data = image.pngData() else {
      XCTFail("Could not encode \(name)")
      return
    }

    try data.write(to: directory.appendingPathComponent("\(name).png"))
  }
}
