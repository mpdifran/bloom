//
//  SignalReportParser.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation

/// Turns what the signal handler managed to write into a report.
///
/// Runs on the launch after the crash, where allocating and parsing are safe again. The handler's
/// side of this contract is deliberately tiny - a signal name, a timestamp, and a list of
/// addresses - because everything it doesn't have to do is something that can't go wrong while
/// the process is dying.
enum SignalReportParser {

  /// The handler's own frames, which are noise: `backtrace` starts inside the handler, so the
  /// first frames are the reporter rather than the crash.
  static let handlerFrameCount = 2

  /// Parses the handler's file. Returns nil if there is nothing usable in it.
  static func parse(
    contents: String,
    images: BinaryImageTable?,
    environment: CrashEnvironment,
    configuration: CrashReportingConfiguration
  ) -> CrashReportPayload? {
    var signalName: String?
    var crashedAt = Date()
    var addresses = [UInt64]()
    var sawEnd = false

    for line in contents.split(whereSeparator: \.isNewline) {
      if line.hasPrefix("SIGNAL ") {
        signalName = String(line.dropFirst("SIGNAL ".count))
      } else if line.hasPrefix("TIME ") {
        if let seconds = TimeInterval(line.dropFirst("TIME ".count)) {
          crashedAt = Date(timeIntervalSince1970: seconds)
        }
      } else if line.hasPrefix("FRAME 0x") {
        if let address = UInt64(line.dropFirst("FRAME 0x".count), radix: 16) {
          addresses.append(address)
        }
      } else if line == "END" {
        sawEnd = true
      }
    }

    guard let signalName, !addresses.isEmpty else { return nil }

    // A file without END means the process died mid-write. What is there is still worth
    // sending - a truncated stack beats no crash at all - but it is worth knowing.
    let frames = self.frames(from: addresses, images: images)

    return CrashReportPayload(
      schemaVersion: configuration.schemaVersion,
      installID: configuration.installID,
      source: .signal,
      dedupeKey: CrashSignature.dedupeKey(
        buildNumber: environment.buildNumber,
        signal: signalName,
        frames: frames
      ),
      appVersion: environment.appVersion,
      buildNumber: environment.buildNumber,
      osVersion: environment.osVersion,
      deviceModel: environment.deviceModel,
      processName: environment.processName,
      exceptionType: signalName,
      exceptionCode: nil,
      signalName: signalName,
      terminationReason: sawEnd ? nil : "Report truncated - the process died while writing it",
      crashThread: "0",
      stackTrace: CrashFrameRenderer.render(frames: frames),
      rawReport: nil,
      binaryImages: images?.images ?? [],
      frames: frames,
      crashedAt: crashedAt
    )
  }

  private static func frames(from addresses: [UInt64], images: BinaryImageTable?) -> [CrashReportPayload.Frame] {
    addresses
      .dropFirst(handlerFrameCount)
      .enumerated()
      .map { index, address in
        let image = images?.image(containing: address)

        return CrashReportPayload.Frame(
          index: index,
          imageName: image?.name,
          imageUUID: image?.uuid,
          address: "0x" + String(address, radix: 16),
          // The offset, not the address, is what survives to the next launch: every
          // launch slides the image somewhere new.
          offset: image.map { Int(address - $0.start) },
          symbol: nil
        )
      }
  }
}
