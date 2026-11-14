//
//  CrashSignatureTests.swift
//  BloomTests
//
//  Created by Mark DiFranco on 2026-11-13.
//

import Testing
@testable import BloomFoundation

@Suite("Crash Signature")
struct CrashSignatureTestSuite {

  // The two reports filed for one CameraPicker crash on 3.3.2: the exception handler's stack starts
  // at the throw, the signal handler's has the abort() machinery on top. Same crash, so same key.
  static let exceptionFrames = frames([
    ("CoreFoundation", "CF", 0x1000),
    ("libobjc.A.dylib", "OBJC", 0x2000),
    ("UIKitCore", "UIKIT", 0x3000),
    ("Bloom", "APP", 0x4000),
    ("SwiftUI", "SWIFTUI", 0x5000),
    ("SwiftUI", "SWIFTUI", 0x6000),
    ("SwiftUICore", "SWIFTUICORE", 0x7000),
  ])

  static let signalFrames = frames([
    ("libsystem_pthread.dylib", "PTHREAD", 0x10),
    ("libsystem_c.dylib", "LIBC", 0x20),
    ("libc++abi.dylib", "CXXABI", 0x30),
    ("libc++abi.dylib", "CXXABI", 0x40),
    ("libobjc.A.dylib", "OBJC", 0x50),
    ("libc++abi.dylib", "CXXABI", 0x60),
    ("libc++abi.dylib", "CXXABI", 0x70),
    ("libc++abi.dylib", "CXXABI", 0x80),
    ("libobjc.A.dylib", "OBJC", 0x90),
    ("UIKitCore", "UIKIT", 0x3000),
    ("Bloom", "APP", 0x4000),
    ("SwiftUI", "SWIFTUI", 0x5000),
    ("SwiftUI", "SWIFTUI", 0x6000),
    ("SwiftUICore", "SWIFTUICORE", 0x7000),
  ])

  @Test("An uncaught exception gets one key from the exception and signal paths")
  func exceptionMatchesSignal() {
    let exception = CrashSignature.dedupeKey(buildNumber: "100", signal: "SIGABRT", frames: Self.exceptionFrames)
    let signal = CrashSignature.dedupeKey(buildNumber: "100", signal: "SIGABRT", frames: Self.signalFrames)

    #expect(exception == signal)
  }

  @Test("MetricKit's numeric signal matches the signal handler's name")
  func metricKitMatchesSignal() {
    let metricKit = CrashSignature.dedupeKey(buildNumber: "100", signal: "SIG6", frames: Self.signalFrames)
    let signal = CrashSignature.dedupeKey(buildNumber: "100", signal: "SIGABRT", frames: Self.signalFrames)

    #expect(metricKit == signal)
  }

  @Test("Different crash sites get different keys")
  func differentSitesDiffer() {
    var other = Self.exceptionFrames
    other[3] = .init(index: 3, imageName: "Bloom", imageUUID: "APP", address: nil, offset: 0x4444, symbol: nil)

    let original = CrashSignature.dedupeKey(buildNumber: "100", signal: "SIGABRT", frames: Self.exceptionFrames)
    let changed = CrashSignature.dedupeKey(buildNumber: "100", signal: "SIGABRT", frames: other)

    #expect(original != changed)
  }

  @Test("A stack of only termination frames still gets a distinct key")
  func onlyTerminationFrames() {
    let first = Self.frames([("libsystem_c.dylib", "LIBC", 0x20), ("libobjc.A.dylib", "OBJC", 0x50)])
    let second = Self.frames([("libsystem_c.dylib", "LIBC", 0x24), ("libobjc.A.dylib", "OBJC", 0x50)])

    #expect(
      CrashSignature.dedupeKey(buildNumber: "100", signal: "SIGABRT", frames: first)
        != CrashSignature.dedupeKey(buildNumber: "100", signal: "SIGABRT", frames: second)
    )
  }

  @Test("Signal names normalise", arguments: [
    ("SIGSEGV", "SIGSEGV"),
    ("EXC_BAD_ACCESS (SIGSEGV)", "SIGSEGV"),
    ("SIG11", "SIGSEGV"),
    ("SIG6", "SIGABRT"),
    ("sigabrt", "SIGABRT"),
    ("SIG99", "SIG99"),
    ("EXC_1", "EXC_1"),
  ])
  func normalize(input: String, expected: String) {
    #expect(CrashSignature.normalize(signal: input) == expected)
  }

  private static func frames(_ entries: [(String, String, Int)]) -> [CrashReportPayload.Frame] {
    entries.enumerated().map { index, entry in
      CrashReportPayload.Frame(
        index: index,
        imageName: entry.0,
        imageUUID: entry.1,
        address: nil,
        offset: entry.2,
        symbol: nil
      )
    }
  }
}
