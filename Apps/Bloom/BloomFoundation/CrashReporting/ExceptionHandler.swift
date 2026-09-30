//
//  ExceptionHandler.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation

/// Catches an Objective-C exception nobody caught.
///
/// Unlike the signal handler this runs with a working runtime, so Foundation and JSON are fine.
/// It writes a report and returns; the runtime then raises `SIGABRT`, which the signal handler
/// sees too - hence the shared dedupe key, so the table gets one crash and not two.
enum ExceptionHandler {

  /// How much of an exception's reason is kept.
  ///
  /// The reason is written by whoever threw, and in a health app that string can end up holding
  /// a food name, a health value or a path with somebody's name in it. Truncated, and `userInfo`
  /// is not sent at all - dumping it wholesale is the most likely way this feature leaks
  /// something it shouldn't.
  static let maximumReasonLength = 512

  private nonisolated(unsafe) static var previousHandler: (@convention(c) (NSException) -> Void)?
  private nonisolated(unsafe) static var writeReport: ((CrashReportPayload) -> Void)?

  static func install(writeReport: @escaping (CrashReportPayload) -> Void) {
    Self.writeReport = writeReport
    Self.previousHandler = NSGetUncaughtExceptionHandler()

    NSSetUncaughtExceptionHandler { exception in
      ExceptionHandler.handle(exception)
      // Anything installed before us still gets its turn - we are a guest in this process.
      ExceptionHandler.previousHandler?(exception)
    }
  }

  private static func handle(_ exception: NSException) {
    let environment = CrashEnvironment.current
    let images = CrashReporter.shared.imageTable

    let symbols = exception.callStackSymbols
    let addresses = exception.callStackReturnAddresses.map { UInt64(truncating: $0) }

    let frames = addresses.enumerated().map { index, address -> CrashReportPayload.Frame in
      let image = images?.image(containing: address)

      return CrashReportPayload.Frame(
        index: index,
        imageName: image?.name,
        imageUUID: image?.uuid,
        address: "0x" + String(address, radix: 16),
        offset: image.map { Int(address - $0.start) },
        symbol: index < symbols.count ? symbols[index] : nil
      )
    }

    let reason = exception.reason.map { String($0.prefix(maximumReasonLength)) }
    let exceptionType = exception.name.rawValue

    let payload = CrashReportPayload(
      schemaVersion: CrashReporter.shared.configuration.schemaVersion,
      installID: CrashReporter.shared.configuration.installID,
      source: .nsexception,
      dedupeKey: CrashSignature.dedupeKey(
        buildNumber: environment.buildNumber,
        signal: "SIGABRT",
        frames: frames
      ),
      appVersion: environment.appVersion,
      buildNumber: environment.buildNumber,
      osVersion: environment.osVersion,
      deviceModel: environment.deviceModel,
      processName: environment.processName,
      exceptionType: exceptionType,
      exceptionCode: reason,
      signalName: nil,
      terminationReason: nil,
      crashThread: "0",
      stackTrace: CrashFrameRenderer.render(frames: frames),
      rawReport: nil,
      binaryImages: images?.images ?? [],
      frames: frames,
      crashedAt: Date()
    )

    writeReport?(payload)
  }
}
