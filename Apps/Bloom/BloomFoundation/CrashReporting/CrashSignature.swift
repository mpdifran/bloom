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

  /// Images whose frames at the top of a stack are the process dying, not the crash site.
  ///
  /// An uncaught exception is seen twice: the exception handler's stack starts where it was thrown
  /// (`__exceptionPreprocess`, `objc_exception_throw`, then the caller), while the signal handler
  /// and MetricKit see the `abort()` that follows (`pthread_kill`, `abort`, `std::terminate`, ...)
  /// stacked on top of that. Skipping these leading frames lets all three start at the same frame.
  static let terminationImages: Set<String> = [
    "libsystem_kernel.dylib",
    "libsystem_pthread.dylib",
    "libsystem_c.dylib",
    "libc++abi.dylib",
    "libobjc.A.dylib",
    "CoreFoundation",
  ]

  static func dedupeKey(buildNumber: String, signal: String, frames: [CrashReportPayload.Frame]) -> String {
    let located = frames.filter { $0.imageUUID != nil && $0.offset != nil }
    let crashSite = located.drop { terminationImages.contains($0.imageName ?? "") }

    // A stack that is nothing but termination frames still needs a key.
    let interesting = (crashSite.isEmpty ? located[...] : crashSite)
      .prefix(frameCount)
      .map { "\($0.imageUUID ?? "")+\($0.offset ?? 0)" }

    let material = ([buildNumber, normalize(signal: signal)] + interesting).joined(separator: "|")
    let digest = SHA256.hash(data: Data(material.utf8))

    return digest.map { String(format: "%02x", $0) }.joined()
  }

  /// One crash, three vocabularies: our handler says `SIGSEGV`, an Apple crash report says
  /// `EXC_BAD_ACCESS (SIGSEGV)`, and MetricKit only gives the number (`SIG11`). Without this the
  /// paths could never agree on a key.
  static func normalize(signal: String) -> String {
    let upper = signal.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

    if upper.hasPrefix("SIG"), let number = Int32(upper.dropFirst(3)), let name = signalNames[number] {
      return name
    }

    for name in signalNames.values where upper.contains(name) {
      return name
    }

    return upper
  }

  private static let signalNames: [Int32: String] = [
    SIGSEGV: "SIGSEGV",
    SIGABRT: "SIGABRT",
    SIGBUS: "SIGBUS",
    SIGILL: "SIGILL",
    SIGFPE: "SIGFPE",
    SIGTRAP: "SIGTRAP",
    SIGKILL: "SIGKILL",
  ]
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
