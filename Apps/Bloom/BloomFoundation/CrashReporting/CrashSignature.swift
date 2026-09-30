//
//  CrashSignature.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation
import CryptoKit

/// Identifies one crash across the paths that report it.
///
/// The signal handler and MetricKit both describe the same crash, from different angles and at
/// different times, so something has to say "these are the same one". That is all this is: not a
/// grouping key - the backend computes that from symbolicated frames - just an identity.
///
/// The addresses themselves can't be used: every launch slides the binaries somewhere new. The
/// offsets into the app's own image can, because they're the same for a given build.
enum CrashSignature {

  /// How many frames are taken. Enough to tell two crash sites apart, few enough that a
  /// slightly different unwind doesn't produce a different key.
  static let frameCount = 5

  static func dedupeKey(buildNumber: String, signal: String, frames: [CrashReportPayload.Frame]) -> String {
    let interesting = frames
      .compactMap { frame -> String? in
        guard let uuid = frame.imageUUID, let offset = frame.offset else { return nil }
        return "\(uuid)+\(offset)"
      }
      .prefix(frameCount)

    let material = ([buildNumber, normalize(signal: signal)] + interesting).joined(separator: "|")
    let digest = SHA256.hash(data: Data(material.utf8))

    return digest.map { String(format: "%02x", $0) }.joined()
  }

  /// One crash, two vocabularies: our handler says `SIGSEGV`, MetricKit says
  /// `EXC_BAD_ACCESS (SIGSEGV)`. Without this the two paths could never agree on a key.
  static func normalize(signal: String) -> String {
    let upper = signal.uppercased()

    for name in ["SIGSEGV", "SIGABRT", "SIGBUS", "SIGILL", "SIGFPE", "SIGTRAP", "SIGKILL"] where upper.contains(name) {
      return name
    }

    return upper.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

// MARK: - Rendering

/// Turns frames into the text an Apple crash report would show.
///
/// The format matters: `Scripts/symbolicate-crashes.sh` parses exactly this shape.
enum CrashFrameRenderer {

  static func render(frames: [CrashReportPayload.Frame]) -> String {
    frames.map { frame in
      let index = String(frame.index).padding(toLength: 4, withPad: " ", startingAt: 0)
      let image = (frame.imageName ?? "???").padding(toLength: 32, withPad: " ", startingAt: 0)
      let address = frame.address ?? "0x0"
      let offset = frame.offset.map(String.init) ?? "0"
      let base = frame.address.flatMap { address -> String? in
        guard let value = UInt64(address.dropFirst(2), radix: 16), let offset = frame.offset else { return nil }
        return "0x" + String(value - UInt64(offset), radix: 16)
      } ?? "0x0"

      return "\(index)\(image)\(address) \(base) + \(offset)"
    }
    .joined(separator: "\n")
  }
}
