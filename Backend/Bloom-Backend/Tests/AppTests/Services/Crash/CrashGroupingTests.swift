//
//  CrashGroupingTests.swift
//  Bloom-Backend
//

@testable import App
import Foundation
import Testing

/// A crash caught by a signal handler always has the kernel's trampoline into that handler on top
/// of the stack, so keying a group on the topmost frame files every crash in the app under
/// `libsystem_platform.dylib`.
@Suite("CrashGrouping")
struct CrashGroupingTests {

  private func makeReport(trace: String, appImages: [String], systemImages: [String] = []) -> CrashReport {
    CrashReport(
      app: CrashApp.bloom.rawValue,
      installID: "install",
      source: "signal",
      dedupeKey: nil,
      appVersion: "3.3.2",
      buildNumber: "412",
      osVersion: "26.0",
      deviceModel: "iPhone17,1",
      exceptionType: "SIGTRAP",
      crashThread: "0",
      stackTrace: trace,
      binaryImages: appImages.map {
        CrashBinaryImage(name: $0, uuid: "A", loadAddress: "0x0", slide: 0, arch: "arm64", isMainExecutable: true, isAppImage: true)
      } + systemImages.map {
        CrashBinaryImage(name: $0, uuid: "B", loadAddress: "0x0", slide: 0, arch: "arm64", isMainExecutable: false, isAppImage: false)
      },
      frames: nil,
      schemaVersion: 1,
      crashedAt: Date()
    )
  }

  @Test("Groups on the first frame belonging to the app")
  func skipsSystemFrames() {
    let report = makeReport(
      trace: """
      0   libsystem_platform.dylib   _sigtramp
      1   libswiftCore.dylib          swift_willThrow
      2   Bloom                       ChatController.send(message:)
      """,
      appImages: ["Bloom"],
      systemImages: ["libsystem_platform.dylib", "libswiftCore.dylib"]
    )

    let signature = CrashGrouping.signature(for: report)

    #expect(signature.contains("ChatController.send"))
    #expect(!signature.contains("_sigtramp"), "The trampoline is in every signal crash and identifies none of them")
  }

  @Test("Two crashes in different app functions do not share a group")
  func differentSitesDiffer() {
    let first = makeReport(
      trace: "0   libsystem_platform.dylib   _sigtramp\n1   Bloom   ChatController.send(message:)",
      appImages: ["Bloom"],
      systemImages: ["libsystem_platform.dylib"]
    )
    let second = makeReport(
      trace: "0   libsystem_platform.dylib   _sigtramp\n1   Bloom   HealthManager.fetchSteps()",
      appImages: ["Bloom"],
      systemImages: ["libsystem_platform.dylib"]
    )

    #expect(CrashGrouping.signature(for: first) != CrashGrouping.signature(for: second))
  }

  @Test("A crash with nothing of ours on the stack still groups")
  func systemOnlyCrash() {
    let report = makeReport(
      trace: "0   libsystem_platform.dylib   _sigtramp\n1   SwiftUI   AG::Graph::update()",
      appImages: ["Bloom"],
      systemImages: ["libsystem_platform.dylib", "SwiftUI"]
    )

    #expect(!CrashGrouping.signature(for: report).isEmpty)
  }

  @Test("Without image information it keys on the top frame")
  func noImages() {
    let report = makeReport(trace: "0   Bloom   something", appImages: [])

    #expect(CrashGrouping.signature(for: report).contains("Bloom"))
  }

  @Test("Addresses and frame indices don't split a group")
  func addressesAreNormalized() {
    let first = CrashSignature.compute(exceptionType: "SIGSEGV", stackTrace: "3   Bloom   0x0000000102f3c1a4 foo() + 120")
    let second = CrashSignature.compute(exceptionType: "SIGSEGV", stackTrace: "7   Bloom   0x00000001049a01a4 foo() + 120")

    #expect(first == second)
  }

  // MARK: dSYM storage

  @Test("dSYM zip names from a build are accepted")
  func validDSYMFilename() {
    #expect(DSYMStorage.isValid(filename: "Bloom-3.3.2-412.dSYMs.zip"))
  }

  @Test("Anything that could escape the dSYM prefix is refused", arguments: [
    "", "../users.zip", "a/b.zip", "..", "name with spaces.zip", String(repeating: "a", count: 201),
  ])
  func invalidDSYMFilename(_ filename: String) {
    #expect(!DSYMStorage.isValid(filename: filename))
  }

  @Test("A frame keeps its group when only its line number moves")
  func lineNumbersAreIgnored() {
    let first = CrashSignature.compute(
      exceptionType: "SIGTRAP",
      stackTrace: "1   Bloom   ChatController.send(message:) (in Bloom) (ChatController.swift:120)"
    )
    let second = CrashSignature.compute(
      exceptionType: "SIGTRAP",
      stackTrace: "1   Bloom   ChatController.send(message:) (in Bloom) (ChatController.swift:131)"
    )

    #expect(first == second)
    #expect(first.contains("ChatController.send(message:)"))
    #expect(!first.contains("(in Bloom)"))
  }
}
