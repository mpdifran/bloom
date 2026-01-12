//
//  MonitorHistoricalAnalysisView.swift
//  Bloom
//
//  Created by Claude on 2026-01-12.
//

import SwiftUI
import SFSafeSymbols

/// Developer tool for analyzing historical monitor data.
/// Shows when state changes and notification triggers would have occurred.
struct MonitorHistoricalAnalysisView: View {

  @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
  @State private var endDate = Date()
  @State private var events: [HistoricalMonitorEvent] = []
  @State private var dailyData: [DailyAnalysisData] = []
  @State private var isAnalyzing = false
  @State private var progress: Double = 0
  @State private var error: Error?
  @State private var showCopiedAlert = false

  var body: some View {
    List {
      dateRangeSection

      runAnalysisSection

      if isAnalyzing {
        progressSection
      }

      if !dailyData.isEmpty {
        exportSection
        summarySection
        resultsSection
      }
    }
    .navigationTitle("Historical Analysis")
    .alert(error: $error)
    .alert("Copied to Clipboard", isPresented: $showCopiedAlert) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("Analysis data has been copied to your clipboard.")
    }
  }
}

// MARK: - Sections

private extension MonitorHistoricalAnalysisView {

  var dateRangeSection: some View {
    Section("Date Range") {
      DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
      DatePicker("End Date", selection: $endDate, displayedComponents: .date)
    }
  }

  var runAnalysisSection: some View {
    Section {
      Button {
        Task {
          await runAnalysis()
        }
      } label: {
        HStack {
          Text("Run Analysis")
          Spacer()
          if isAnalyzing {
            ProgressView()
          }
        }
      }
      .disabled(isAnalyzing || startDate > endDate)
    } footer: {
      Text("Analyzes each day in the range to find state changes and notification triggers.")
    }
  }

  var progressSection: some View {
    Section("Progress") {
      VStack(alignment: .leading, spacing: 8) {
        ProgressView(value: progress)
        Text("\(Int(progress * 100))% complete")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  var exportSection: some View {
    Section {
      Button {
        copyAnalysisData()
      } label: {
        HStack {
          Text("Copy Analysis Data")
          Spacer()
          Image(systemSymbol: .docOnClipboard)
        }
      }
    } footer: {
      Text("Copies detailed metric data for each day to clipboard in Markdown format for debugging.")
    }
  }

  var summarySection: some View {
    Section("Summary") {
      let stateChanges = events.filter { $0.eventType == .stateChange }.count
      let notifications = events.filter { $0.eventType == .notificationTrigger }.count

      LabeledContent("Total Events", value: "\(events.count)")
      LabeledContent("State Changes", value: "\(stateChanges)")
      LabeledContent("Notification Triggers", value: "\(notifications)")

      ForEach(MonitorType.allCases, id: \.self) { type in
        let typeEvents = events.filter { $0.monitorType == type }
        let typeNotifications = typeEvents.filter { $0.eventType == .notificationTrigger }.count
        LabeledContent(type.displayName, value: "\(typeEvents.count) events (\(typeNotifications) notifications)")
          .font(.caption)
      }
    }
  }

  var resultsSection: some View {
    Section("Events (\(events.count))") {
      ForEach(events) { event in
        HistoricalEventCell(event: event)
      }
    }
  }
}

// MARK: - Actions

private extension MonitorHistoricalAnalysisView {

  func runAnalysis() async {
    isAnalyzing = true
    progress = 0
    events = []
    dailyData = []

    do {
      let analyzer = MonitorHistoricalAnalyzer()
      let result = try await analyzer.analyzeWithFullData(
        from: startDate,
        to: endDate,
        progressHandler: { newProgress in
          Task { @MainActor in
            self.progress = newProgress
          }
        }
      )
      events = result.events
      dailyData = result.dailyData
    } catch {
      self.error = error
    }

    isAnalyzing = false
  }

  func copyAnalysisData() {
    let markdown = formatAnalysisDataAsMarkdown()
    UIPasteboard.general.string = markdown
    showCopiedAlert = true
  }

  func formatAnalysisDataAsMarkdown() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium

    var output = "# Monitor Analysis: \(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))\n\n"

    for dayData in dailyData {
      output += "## \(dateFormatter.string(from: dayData.date))\n\n"

      // Group results by monitor type
      for monitorType in MonitorType.allCases {
        guard let result = dayData.monitorResults.first(where: { $0.monitorType == monitorType }) else {
          continue
        }

        var headerLine = "### \(monitorType.displayName): \(result.state.displayName) (\(Int(result.confidence * 100))% confidence, \(result.consecutiveDays) consecutive days)"

        // Add stress subtype for stress monitor
        if monitorType == .stress, let subtype = result.stressSubtype {
          headerLine += " - **\(subtype.displayName)**"
        }

        output += headerLine + "\n\n"

        // Metrics table for this monitor
        let monitorMetrics = dayData.metrics.filter { $0.metricType.monitor == monitorType }

        if !monitorMetrics.isEmpty {
          output += "#### Metrics\n"
          output += "| Metric | Value | 7-Day Baseline | 28-Day Baseline | Z-Score | Quality |\n"
          output += "|--------|-------|----------------|-----------------|---------|--------|\n"

          for metric in monitorMetrics {
            let valueStr = metric.value.map { metric.metricType.formatValue($0) } ?? "N/A"
            let baseline7Str = metric.baseline7Day.map { metric.metricType.formatValueShort($0) } ?? "N/A"
            let baseline28Str = metric.baseline28Day.map { metric.metricType.formatValueShort($0) } ?? "N/A"
            let zScoreStr = metric.zScore.map { String(format: "%+.2f", $0) } ?? "N/A"
            let qualityStr = metric.quality ?? "N/A"

            output += "| \(metric.metricType.displayName) | \(valueStr) | \(baseline7Str) | \(baseline28Str) | \(zScoreStr) | \(qualityStr) |\n"
          }
          output += "\n"
        }

        // Signals
        if !result.signals.isEmpty {
          output += "#### Signals Detected\n"
          for signal in result.signals {
            output += "- **\(signal.metricType.displayName)**: \(signal.description) (z-score: \(String(format: "%+.2f", signal.zScore)), direction: \(signal.direction.rawValue))\n"
          }
          output += "\n"
        } else {
          output += "#### Signals Detected\n- None\n\n"
        }

        // Findings
        if !result.findings.isEmpty {
          output += "#### Findings\n"
          for finding in result.findings {
            output += "- **\(finding.title)** (\(finding.confidence.rawValue) confidence)\n"
          }
          output += "\n"
        }
      }

      output += "---\n\n"
    }

    return output
  }
}

// MARK: - Event Cell

struct HistoricalEventCell: View {
  let event: HistoricalMonitorEvent

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      // Header row with badge, monitor type, and date
      HStack {
        eventTypeBadge

        Text(event.monitorType.displayName)
          .font(.subheadline)
          .fontWeight(.medium)

        // Show stress subtype badge for stress monitor
        if event.monitorType == .stress, let subtype = event.stressSubtype {
          stressSubtypeBadge(subtype)
        }

        Spacer()

        Text(event.date, style: .date)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      // State transition row
      HStack(spacing: 6) {
        if let prev = event.previousState {
          Text(prev.displayName)
            .foregroundStyle(prev.color)
        } else {
          Text("None")
            .foregroundStyle(.secondary)
        }

        Image(systemSymbol: .arrowRight)
          .font(.caption2)
          .foregroundStyle(.secondary)

        Text(event.newState.displayName)
          .foregroundStyle(event.newState.color)
      }
      .font(.caption)

      // Confidence
      Text("Confidence: \(Int(event.confidence * 100))%")
        .font(.caption2)
        .foregroundStyle(.secondary)

      // Signals summary
      if !event.signals.isEmpty {
        Text("Signals: \(event.signals.map { $0.metricType.displayName }.joined(separator: ", "))")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      // Findings count
      if !event.findings.isEmpty {
        Text("\(event.findings.count) finding(s)")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }

  private var eventTypeBadge: some View {
    Text(event.eventType == .notificationTrigger ? "NOTIFY" : "CHANGE")
      .font(.caption2)
      .fontWeight(.semibold)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(event.eventType == .notificationTrigger ? Color.orange : Color.blue)
      .foregroundStyle(.white)
      .clipShape(Capsule())
  }

  private func stressSubtypeBadge(_ subtype: StressSubtype) -> some View {
    Text(subtype == .burnout ? "BURNOUT" : "TRAINING")
      .font(.caption2)
      .fontWeight(.semibold)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(subtype == .burnout ? Color.purple : Color.green)
      .foregroundStyle(.white)
      .clipShape(Capsule())
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    NavigationStack {
      MonitorHistoricalAnalysisView()
    }
  }
}
