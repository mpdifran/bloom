//
//  CrashReporter.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation

/// Collects crashes and sends them on.
///
/// The one type the rest of the app talks to. Every process installs it as early as it can - the
/// apps from their `init`, each extension from its principal class - and the apps drain the queue
/// when they become active. Ported from AirChat, which reports into Northstar the same way.
///
/// Nothing in `CrashReporting` knows about health, food or chat - the only thing it knows about
/// this app is `CrashReportingConfiguration`.
public final class CrashReporter: @unchecked Sendable {

  public static let shared = CrashReporter(configuration: .bloom)

  public let configuration: CrashReportingConfiguration

  private let store: PendingCrashStore
  private let uploader: CrashUploader

  /// Guards everything below, plus `isDraining`.
  private let lock = NSLock()

  /// The images loaded at install, kept so a crash can be attributed to one without reading mach
  /// headers at the worst possible moment.
  private var _imageTable: BinaryImageTable?

  /// Apple's own crash reports, which arrive a launch or a day later and cover terminations no
  /// in-process handler can see.
  private var metricKitCollector: MetricKitCollector?

  private var isInstalled = false
  private var isDraining = false

  init(
    configuration: CrashReportingConfiguration,
    store: PendingCrashStore = .shared,
    uploader: CrashUploader? = nil
  ) {
    self.configuration = configuration
    self.store = store
    self.uploader = uploader ?? CrashUploader(configuration: configuration)
  }

  var imageTable: BinaryImageTable? {
    lock.withLock { _imageTable }
  }

  /// Whether the person has left crash reporting on. Defaults to on.
  public var isEnabled: Bool {
    let defaults = UserDefaults.groupIfAvailable ?? .standard
    return defaults.object(forKey: .crashReportingEnabledKey) as? Bool ?? true
  }
}

// MARK: - Lifecycle

public extension CrashReporter {

  /// Called as early in launch as there is code to call it from. Safe to call more than once;
  /// only the first does anything.
  ///
  /// Order matters: read the last launch's crash file before the handler truncates it, then take
  /// the image table, then arm the handlers.
  func install() {
    guard isEnabled else {
      store.removeAll()
      return
    }

    let shouldInstall = lock.withLock {
      guard !isInstalled else { return false }
      isInstalled = true
      return true
    }
    guard shouldInstall else { return }

    collectPreviousCrash()

    let table = BinaryImageTable.current()
    lock.withLock { _imageTable = table }
    store.writeImageTable(table)

    SignalHandler.install(reportPath: store.signalReportURL.path)
    ExceptionHandler.install { [store] payload in
      // Written straight to disk: the process is a moment from death and an upload would not
      // finish.
      _ = store.store(payload)
    }

    if configuration.collectsMetricKit {
      let collector = MetricKitCollector { [store] payload in
        _ = store.store(payload)
      }
      collector.subscribe()
      lock.withLock { metricKitCollector = collector }
    }
  }

  /// Sends whatever is waiting, including what the extensions queued. Safe to call often; it exits
  /// immediately when there is nothing due, and never runs twice at once.
  func drainPending() async {
    guard configuration.uploadsReports else { return }

    guard isEnabled else {
      store.removeAll()
      return
    }

    let shouldDrain = lock.withLock {
      guard !isDraining else { return false }
      isDraining = true
      return true
    }
    guard shouldDrain else { return }

    defer {
      lock.withLock { isDraining = false }
    }

    for stored in store.readyEntries() {
      let outcome = await uploader.upload(stored.entry.payload)

      switch outcome {
      case .accepted:
        store.remove(stored)
      case .rejected:
        // It will be refused identically every time; keeping it only fills the queue.
        store.remove(stored)
      case .retryable:
        store.recordFailure(for: stored)
      }
    }
  }

  /// Queues a report. Sending happens later - a crash is a bad moment to wait on the network.
  @discardableResult
  func report(_ payload: CrashReportPayload) -> Bool {
    guard isEnabled else { return false }

    return store.store(payload)
  }

  /// Throws away everything queued, and stops listening. Called when crash reporting is switched
  /// off: anything already queued would otherwise go out the moment it was switched back on, which
  /// is not what "off" means.
  func discardPending() {
    let collector = lock.withLock {
      defer { metricKitCollector = nil }
      return metricKitCollector
    }
    collector?.unsubscribe()
    store.removeAll()
  }

  /// How many reports are waiting, for the developer screen.
  var pendingReportCount: Int {
    store.allEntries().count
  }
}

// MARK: - Previous crash

private extension CrashReporter {

  /// Reads what the handler wrote before this process last died, and queues it.
  func collectPreviousCrash() {
    guard let contents = store.readSignalReport() else { return }

    defer { store.clearSignalReport() }

    // The images of the launch that crashed, not this one: the addresses belong to that process's
    // layout and mean nothing against this one's.
    let images = store.readImageTable()

    guard
      let payload = SignalReportParser.parse(
        contents: contents,
        images: images,
        environment: .current,
        configuration: configuration
      )
    else {
      return
    }

    _ = store.store(payload)
  }
}
