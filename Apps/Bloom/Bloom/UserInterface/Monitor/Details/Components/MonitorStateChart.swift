//
//  MonitorStateChart.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI
import Charts

/// A chart displaying monitor state history over time.
struct MonitorStateChart: View {

  let results: [MonitorResult]
  let monitorType: MonitorType

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("State History")
        .font(.headline)

      if results.isEmpty {
        emptyChart
      } else {
        chart
      }

      legend
    }
  }

  // MARK: - Chart

  private var chart: some View {
    Chart {
      ForEach(results) { result in
        BarMark(
          x: .value("Date", result.calculatedAt, unit: .day),
          y: .value("State", 1)
        )
        .foregroundStyle(result.state.color)
        .cornerRadius(4)
      }
    }
    .chartYAxis(.hidden)
    .chartXAxis {
      AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
        AxisGridLine()
      }
    }
    .frame(height: 60)
  }

  private var xAxisStride: Int {
    // Show fewer labels for longer periods
    results.count > 14 ? 7 : 1
  }

  // MARK: - Empty State

  private var emptyChart: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color(.systemGray6))
      .frame(height: 60)
      .overlay {
        Text("No history available")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
  }

  // MARK: - Legend

  private var legend: some View {
    HStack(spacing: 16) {
      legendItem(state: .good)
      legendItem(state: .attention)
      legendItem(state: .alert)
      if monitorType == .stress {
        legendItem(state: .encourage)
      }
    }
    .font(.caption)
  }

  private func legendItem(state: MonitorStateValue) -> some View {
    HStack(spacing: 4) {
      Circle()
        .fill(state.color)
        .frame(width: 8, height: 8)
      Text(state.displayName)
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    VStack(spacing: 32) {
      MonitorStateChart(
        results: [
          MonitorResult(
            monitorType: .recovery,
            state: .good,
            confidence: 0.8,
            consecutiveDays: 1,
            signals: [],
            findings: [],
            calculatedAt: Calendar.current.date(byAdding: .day, value: -6, to: Date())!
          ),
          MonitorResult(
            monitorType: .recovery,
            state: .good,
            confidence: 0.8,
            consecutiveDays: 2,
            signals: [],
            findings: [],
            calculatedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!
          ),
          MonitorResult(
            monitorType: .recovery,
            state: .attention,
            confidence: 0.8,
            consecutiveDays: 1,
            signals: [],
            findings: [],
            calculatedAt: Calendar.current.date(byAdding: .day, value: -4, to: Date())!
          ),
          MonitorResult(
            monitorType: .recovery,
            state: .attention,
            confidence: 0.8,
            consecutiveDays: 2,
            signals: [],
            findings: [],
            calculatedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!
          ),
          MonitorResult(
            monitorType: .recovery,
            state: .alert,
            confidence: 0.9,
            consecutiveDays: 1,
            signals: [],
            findings: [],
            calculatedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
          ),
          MonitorResult(
            monitorType: .recovery,
            state: .attention,
            confidence: 0.8,
            consecutiveDays: 1,
            signals: [],
            findings: [],
            calculatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
          ),
          MonitorResult(
            monitorType: .recovery,
            state: .good,
            confidence: 0.85,
            consecutiveDays: 1,
            signals: [],
            findings: [],
            calculatedAt: Date()
          )
        ],
        monitorType: .recovery
      )
      .cardContainer()
    }
    .padding()
  }
}
