//
//  LogManager.swift
//  Bloom
//
//  Created by Assistant on 2025-01-26.
//

import Foundation

enum LogTag: String, Codable, CaseIterable, Identifiable {
  case biologicalAge = "Biological Age"
  case monitorAggregation = "Monitor Aggregation"
  case workoutAnalysis = "Workout Analysis"

  var id: String { rawValue }
}

struct LogEntry: Codable, Identifiable {
  let id: UUID
  let timestamp: Date
  let tag: LogTag
  let message: String

  init(tag: LogTag, message: String) {
    self.id = UUID()
    self.timestamp = Date()
    self.tag = tag
    self.message = message
  }
}

private extension String {
  static let logEntries = "LogManager.entries"
}

@MainActor
final class LogManager: ObservableObject {
  static let shared = LogManager()

  private let maxLogs = 1000

  @Published private(set) var logs: [LogEntry] = []

  private init() {
    loadLogs()
  }

  func log(_ tag: LogTag, _ message: String) {
    let entry = LogEntry(tag: tag, message: message)
    logs.append(entry)

    // Prune old logs if we exceed max
    if logs.count > maxLogs {
      logs.removeFirst(logs.count - maxLogs)
    }

    saveLogs()
  }

  func clearLogs() {
    logs = []
    saveLogs()
  }

  func exportLogsAsJSON() -> String {
    guard let data = try? JSONEncoder().encode(logs),
          let json = String(data: data, encoding: .utf8) else {
      return "[]"
    }
    return json
  }

  private func saveLogs() {
    guard let data = try? JSONEncoder().encode(logs) else { return }
    UserDefaults.standard.set(data, forKey: .logEntries)
  }

  private func loadLogs() {
    guard let data = UserDefaults.standard.data(forKey: .logEntries),
          let entries = try? JSONDecoder().decode([LogEntry].self, from: data) else {
      logs = []
      return
    }
    logs = entries
  }
}

// MARK: - Global Convenience Function

func internalLog(_ tag: LogTag, _ message: String) {
  Task { @MainActor in
    LogManager.shared.log(tag, message)
  }
}
