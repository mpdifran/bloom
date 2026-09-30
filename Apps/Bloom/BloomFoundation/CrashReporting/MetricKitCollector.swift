//
//  MetricKitCollector.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation
#if os(iOS)
import MetricKit
#endif

/// Crash reports written by the system rather than by us.
///
/// Worth having alongside the signal handler for two reasons. Apple's unwinder is a real one -
/// it sees inlined frames and unwinds through code ours cannot - and MetricKit reports
/// terminations that no handler in the process can ever see: watchdog kills, out-of-memory
/// terminations, and the app being killed outright.
///
/// The cost is latency. A payload arrives at most once a day, shortly after a launch, so this
/// complements the handler rather than replacing it.
final class MetricKitCollector: NSObject {

  private let report: (CrashReportPayload) -> Void

  init(report: @escaping (CrashReportPayload) -> Void) {
    self.report = report
    super.init()
  }

  func subscribe() {
    #if os(iOS) && !targetEnvironment(simulator)
    MXMetricManager.shared.add(self)
    #endif
  }

  func unsubscribe() {
    #if os(iOS) && !targetEnvironment(simulator)
    MXMetricManager.shared.remove(self)
    #endif
  }
}

#if os(iOS) && !targetEnvironment(simulator)

extension MetricKitCollector: MXMetricManagerSubscriber {

  func didReceive(_ payloads: [MXMetricPayload]) {
    // Performance metrics, not crashes. Nothing to do with this.
  }

  func didReceive(_ payloads: [MXDiagnosticPayload]) {
    let environment = CrashEnvironment.current

    for payload in payloads {
      for diagnostic in payload.crashDiagnostics ?? [] {
        guard let crash = Self.payload(
          from: diagnostic,
          environment: environment,
          configuration: CrashReporter.shared.configuration,
          // MetricKit gives no exact crash time, only the window the payload covers.
          crashedAt: payload.timeStampEnd
        ) else {
          continue
        }

        report(crash)
      }
    }
  }

  /// Which binaries in a MetricKit stack are ours. It reports names, not paths, so this is
  /// the executable's name plus the Debug build's dylib.
  private static var appImageNames: Set<String> {
    let executable = Bundle.main.executableURL?.lastPathComponent ?? "Bloom"
    return [executable, executable + ".debug.dylib"]
  }

  private static func payload(
    from diagnostic: MXCrashDiagnostic,
    environment: CrashEnvironment,
    configuration: CrashReportingConfiguration,
    crashedAt: Date
  ) -> CrashReportPayload? {
    let tree = diagnostic.callStackTree.jsonRepresentation()
    let frames = CallStackTreeParser.frames(fromJSON: tree)

    let signalName = diagnostic.signal.map { "SIG\($0.intValue)" }
    let exceptionType = diagnostic.exceptionType.map { "EXC_\($0.intValue)" } ?? "Unknown"

    // The metadata belongs to the launch that crashed, not this one. Using what MetricKit
    // reports means the version is the version that actually crashed, even if the app has
    // been updated since.
    let metadata = diagnostic.metaData

    return CrashReportPayload(
      schemaVersion: configuration.schemaVersion,
      installID: configuration.installID,
      source: .metrickit,
      dedupeKey: CrashSignature.dedupeKey(
        buildNumber: metadata.applicationBuildVersion,
        signal: signalName ?? exceptionType,
        frames: frames
      ),
      appVersion: diagnostic.applicationVersion,
      buildNumber: metadata.applicationBuildVersion,
      osVersion: metadata.osVersion,
      deviceModel: metadata.deviceType,
      processName: CrashEnvironment.current.processName,
      exceptionType: exceptionType,
      exceptionCode: diagnostic.exceptionCode.map(\.stringValue),
      signalName: signalName,
      terminationReason: diagnostic.terminationReason,
      crashThread: "0",
      stackTrace: CrashFrameRenderer.render(frames: frames),
      rawReport: String(data: tree, encoding: .utf8).map { String($0.prefix(32_000)) },
      binaryImages: CallStackTreeParser.images(fromJSON: tree, appImageNames: Self.appImageNames),
      frames: frames,
      crashedAt: crashedAt
    )
  }
}

#endif

// MARK: - Parsing

/// Reads Apple's call stack tree.
///
/// Takes `Data` rather than an `MXCallStackTree` on purpose: `MXCrashDiagnostic` cannot be
/// constructed in a test, but the JSON it produces can be captured once and replayed forever.
///
/// The tree already carries what symbolication needs - a UUID and an offset into the text
/// segment per frame - produced by Apple's own unwinder rather than a frame-pointer walk.
enum CallStackTreeParser {

  static func frames(fromJSON data: Data) -> [CrashReportPayload.Frame] {
    guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }

    // The crashing thread is the one flagged as attributed; fall back to the first.
    let stacks = root["callStacks"] as? [[String: Any]] ?? []
    let stack = stacks.first { $0["threadAttributed"] as? Bool == true } ?? stacks.first

    guard let roots = stack?["callStackRootFrames"] as? [[String: Any]] else { return [] }

    var flattened = [[String: Any]]()
    for frame in roots {
      flatten(frame: frame, into: &flattened)
    }

    return flattened.enumerated().map { index, frame in
      let uuid = (frame["binaryUUID"] as? String)?.uppercased().replacingOccurrences(of: "-", with: "")
      let offset = frame["offsetIntoBinaryTextSegment"] as? Int

      return CrashReportPayload.Frame(
        index: index,
        imageName: frame["binaryName"] as? String,
        imageUUID: uuid,
        // MetricKit reports an offset, never a runtime address - which is the more
        // useful of the two, since an address is meaningless without its slide.
        address: nil,
        offset: offset,
        symbol: nil
      )
    }
  }

  /// The distinct binaries the stack touched.
  ///
  /// There is no load address to record: MetricKit reports offsets into each binary's text
  /// segment instead, which is the more useful half - an offset survives the slide that makes
  /// a runtime address meaningless. The symbolicator adds the dSYM's own text vmaddr.
  static func images(fromJSON data: Data, appImageNames: Set<String>) -> [CrashReportPayload.BinaryImage] {
    var seen = Set<String>()
    var images = [CrashReportPayload.BinaryImage]()

    for frame in frames(fromJSON: data) {
      guard let uuid = frame.imageUUID, !seen.contains(uuid) else { continue }
      seen.insert(uuid)

      let name = frame.imageName ?? "???"
      images.append(
        CrashReportPayload.BinaryImage(
          name: name,
          uuid: uuid,
          loadAddress: "0x0",
          slide: nil,
          arch: nil,
          isMainExecutable: appImageNames.contains(name),
          isAppImage: appImageNames.contains(name)
        )
      )
    }

    return images
  }

  /// The tree nests each callee inside its caller; a stack is that walked depth-first.
  private static func flatten(frame: [String: Any], into result: inout [[String: Any]]) {
    result.append(frame)

    guard let children = frame["subFrames"] as? [[String: Any]] else { return }

    for child in children {
      flatten(frame: child, into: &result)
    }
  }
}
