//
//  PendingCrashStore.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation

/// Holds crash reports until they can be sent.
///
/// `@unchecked Sendable` because every read and write goes through `queue`.
///
/// A serial queue, JSON on disk in the app group, and a capped exponential backoff per entry.
///
/// One report per file, not one file holding an array. The signal handler writes into a file
/// descriptor opened before the crash, with `write(2)` and nothing else - it cannot read, parse
/// and rewrite a JSON array while the process is coming apart. The layout follows from that.
///
/// It also means the app and its extensions can share one queue: each writes its own files, and
/// the app sends all of them.
///
/// A failed upload keeps the report. Deleting it whatever the outcome would mean a crash reported
/// while the backend was down is a crash nobody ever hears about.
final class PendingCrashStore: @unchecked Sendable {

  /// Past this many, the oldest is dropped. A crash loop can otherwise fill the container with
  /// reports of the same bug.
  static let maximumReports = 20

  /// Older than this and nobody is going to fix it from here.
  static let maximumAge: TimeInterval = 14 * 24 * 3600

  static let shared = PendingCrashStore()

  private let queue = DispatchQueue(label: "com.lotus-labs.bloom.PendingCrashStore")
  fileprivate let directory: URL

  /// The directory is injected so tests don't write into the real app group container.
  init(directory: URL? = nil) {
    self.directory = directory ?? Self.defaultDirectory
    self.createDirectoryIfNeeded()
  }
}

// MARK: - Storing

extension PendingCrashStore {

  /// Files a report to be sent later. Returns false if it was dropped as a duplicate.
  @discardableResult
  func store(_ payload: CrashReportPayload) -> Bool {
    queue.sync {
      if let dedupeKey = payload.dedupeKey, self.recentDedupeKeysLocked().contains(dedupeKey) {
        return false
      }

      let entry = Entry(payload: payload, attempts: 0, firstStoredAt: Date(), lastAttemptAt: .distantPast)
      guard let data = try? Self.encoder.encode(entry) else { return false }

      let url = self.directory.appendingPathComponent("pending-\(UUID().uuidString).json")
      try? data.write(to: url, options: .atomic)

      if let dedupeKey = payload.dedupeKey {
        self.rememberDedupeKeyLocked(dedupeKey)
      }

      self.enforceLimitsLocked()
      return true
    }
  }

  /// Everything waiting, oldest first, that is due another attempt.
  func readyEntries(now: Date = Date()) -> [StoredEntry] {
    queue.sync {
      self.allEntriesLocked()
        .filter { $0.entry.isReady(now: now) }
        .sorted { $0.entry.firstStoredAt < $1.entry.firstStoredAt }
    }
  }

  func allEntries() -> [StoredEntry] {
    queue.sync { self.allEntriesLocked() }
  }

  /// Sent, or refused in a way that will never change. Either way it is done with.
  func remove(_ stored: StoredEntry) {
    queue.sync {
      try? FileManager.default.removeItem(at: stored.url)
    }
  }

  /// Didn't get through. Back off and try again later.
  func recordFailure(for stored: StoredEntry, now: Date = Date()) {
    queue.sync {
      var entry = stored.entry
      entry.attempts += 1
      entry.lastAttemptAt = now

      guard let data = try? Self.encoder.encode(entry) else { return }
      try? data.write(to: stored.url, options: .atomic)
    }
  }

  /// Crash reporting was switched off. Nothing queued should outlive that.
  func removeAll() {
    queue.sync {
      let contents = try? FileManager.default.contentsOfDirectory(at: self.directory, includingPropertiesForKeys: nil)
      contents?.forEach { try? FileManager.default.removeItem(at: $0) }
    }
  }
}

// MARK: - The signal handler's file

extension PendingCrashStore {

  /// Where the signal handler writes. Opened at install, written to during a crash, read on
  /// the launch after.
  ///
  /// One per process: the app and each extension arm their own handler at launch, and opening the
  /// file truncates it - a shared one would be wiped by whichever process started next.
  var signalReportURL: URL {
    directory.appendingPathComponent("signal-crash-\(Self.processFileSuffix).txt")
  }

  private var imageTableURL: URL {
    directory.appendingPathComponent("binary-images-\(Self.processFileSuffix).json")
  }

  private static var processFileSuffix: String {
    CrashEnvironment.current.processName
      .map { $0.isLetter || $0.isNumber ? $0 : "-" }
      .reduce(into: "") { $0.append($1) }
  }

  /// What the handler wrote last time, if it ran at all.
  func readSignalReport() -> String? {
    queue.sync {
      guard
        let data = try? Data(contentsOf: self.signalReportURL),
        !data.isEmpty,
        let contents = String(data: data, encoding: .utf8)
      else {
        return nil
      }

      return contents
    }
  }

  func clearSignalReport() {
    queue.sync {
      try? FileManager.default.removeItem(at: self.signalReportURL)
    }
  }

  /// Kept beside the crash file because the addresses in one are meaningless without the other.
  func writeImageTable(_ table: BinaryImageTable) {
    queue.sync {
      guard let data = try? Self.encoder.encode(table) else { return }
      try? data.write(to: self.imageTableURL, options: .atomic)
    }
  }

  /// The image layout of the launch that crashed - written before the handlers were armed, and
  /// read back before this launch overwrites it.
  func readImageTable() -> BinaryImageTable? {
    queue.sync {
      guard
        let data = try? Data(contentsOf: self.imageTableURL),
        let table = try? Self.decoder.decode(BinaryImageTable.self, from: data)
      else {
        return nil
      }

      return table
    }
  }
}

// MARK: - Entries

extension PendingCrashStore {

  struct Entry: Codable {
    let payload: CrashReportPayload
    var attempts: Int
    var firstStoredAt: Date
    var lastAttemptAt: Date

    /// Widening intervals, capped at a day - the same arithmetic `FailedSyncStore` uses, and
    /// for the same reason: a backend that is down for an afternoon shouldn't be hammered,
    /// and a report shouldn't be abandoned because of it either.
    func isReady(now: Date) -> Bool {
      guard attempts > 0 else { return true }

      let backoff = min(pow(2, Double(attempts)) * 60, 86_400)
      return now.timeIntervalSince(lastAttemptAt) >= backoff
    }
  }

  struct StoredEntry {
    let url: URL
    let entry: Entry
  }
}

// MARK: - Disk

extension PendingCrashStore {

  fileprivate static let encoder = CrashReportPayload.makeEncoder()
  fileprivate static let decoder = CrashReportPayload.makeDecoder()

  static let dedupeKeysFileName = "recent-dedupe-keys.json"

  /// Kept in the app group so the extensions file their crashes into the queue the app sends.
  static var defaultDirectory: URL {
    let groupIdentifier = Bundle.main.object(forInfoDictionaryKey: "BLOOM_APP_GROUP_ID") as? String
    let container = groupIdentifier.flatMap {
      FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0)
    }

    let base = container ?? URL.documentsDirectory
    return base.appendingPathComponent("crash-reports", isDirectory: true)
  }

  func createDirectoryIfNeeded() {
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    // A crash on a launch after a reboot, before the phone has been unlocked once, would
    // otherwise find its own queue unreadable.
    try? FileManager.default.setAttributes(
      [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
      ofItemAtPath: directory.path
    )
  }

  func allEntriesLocked() -> [StoredEntry] {
    let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []

    return urls.compactMap { url in
      guard url.lastPathComponent.hasPrefix("pending-") else { return nil }

      guard
        let data = try? Data(contentsOf: url),
        let entry = try? Self.decoder.decode(Entry.self, from: data)
      else {
        // Unreadable, and it will still be unreadable next launch. Leaving it would
        // block the queue behind it forever.
        try? FileManager.default.removeItem(at: url)
        return nil
      }

      return StoredEntry(url: url, entry: entry)
    }
  }

  func enforceLimitsLocked() {
    var entries = allEntriesLocked()

    let cutoff = Date(timeIntervalSinceNow: -Self.maximumAge)
    for stored in entries where stored.entry.firstStoredAt < cutoff {
      try? FileManager.default.removeItem(at: stored.url)
    }
    entries = entries.filter { $0.entry.firstStoredAt >= cutoff }

    guard entries.count > Self.maximumReports else { return }

    let oldestFirst = entries.sorted { $0.entry.firstStoredAt < $1.entry.firstStoredAt }
    for stored in oldestFirst.prefix(entries.count - Self.maximumReports) {
      try? FileManager.default.removeItem(at: stored.url)
    }
  }

  // MARK: Dedupe keys

  /// The handler and MetricKit describe the same crash. Remembering what has already been
  /// filed is the cheap half of not reporting it twice; the backend does the other half.
  func recentDedupeKeysLocked() -> [String] {
    let url = directory.appendingPathComponent(Self.dedupeKeysFileName)

    guard
      let data = try? Data(contentsOf: url),
      let keys = try? Self.decoder.decode([String].self, from: data)
    else {
      return []
    }

    return keys
  }

  func rememberDedupeKeyLocked(_ key: String) {
    var keys = recentDedupeKeysLocked()
    keys.append(key)
    keys = Array(keys.suffix(50))

    let url = directory.appendingPathComponent(Self.dedupeKeysFileName)
    guard let data = try? Self.encoder.encode(keys) else { return }
    try? data.write(to: url, options: .atomic)
  }
}
