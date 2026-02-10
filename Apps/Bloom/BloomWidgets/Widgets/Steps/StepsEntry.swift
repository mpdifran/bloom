//
//  StepsEntry.swift
//  BloomWidgets
//
//  Created by Claude Code on 2026-02-09.
//

import Foundation
import WidgetKit

// MARK: - Chart Data

struct StepChartPoint: Identifiable {
  var id: Int { slot }
  let slot: Int
  let cumulativeSteps: Int
}

// MARK: - Timeline Entry

struct StepsEntry: TimelineEntry {
  let date: Date
  let timePeriod: StepsWidgetTimePeriod
  let steps: Int?
  let distance: Double?
  let distanceUnitString: String
  let chartDataPoints: [StepChartPoint]
  let totalSlots: Int

  static func placeholder(for timePeriod: StepsWidgetTimePeriod = .daily) -> StepsEntry {
    let (chartData, totalSlots) = previewData(for: timePeriod)
    return StepsEntry(
      date: .now,
      timePeriod: timePeriod,
      steps: previewSteps(for: timePeriod),
      distance: previewDistance(for: timePeriod),
      distanceUnitString: "km",
      chartDataPoints: chartData,
      totalSlots: totalSlots
    )
  }

  static func empty(for timePeriod: StepsWidgetTimePeriod = .daily) -> StepsEntry {
    StepsEntry(
      date: .now,
      timePeriod: timePeriod,
      steps: nil,
      distance: nil,
      distanceUnitString: "km",
      chartDataPoints: [],
      totalSlots: defaultTotalSlots(for: timePeriod)
    )
  }
}

// MARK: - Preview Helpers

private func defaultTotalSlots(for timePeriod: StepsWidgetTimePeriod) -> Int {
  switch timePeriod {
  case .daily: 24
  case .weekly: 42
  case .monthly: 31
  case .yearly: 12
  }
}

private func previewSteps(for timePeriod: StepsWidgetTimePeriod) -> Int {
  switch timePeriod {
  case .daily: 4218
  case .weekly: 42350
  case .monthly: 185400
  case .yearly: 2150000
  }
}

private func previewDistance(for timePeriod: StepsWidgetTimePeriod) -> Double {
  switch timePeriod {
  case .daily: 2.3
  case .weekly: 28.5
  case .monthly: 124.3
  case .yearly: 1450.0
  }
}

private func previewData(for timePeriod: StepsWidgetTimePeriod) -> ([StepChartPoint], Int) {
  let totalSlots = defaultTotalSlots(for: timePeriod)
  let steps = previewSteps(for: timePeriod)

  switch timePeriod {
  case .daily:
    return (previewDailyChartData(throughSlot: 15, totalSteps: steps), totalSlots)
  case .weekly:
    return (previewCumulativeChartData(throughSlot: 21, totalSlots: totalSlots, totalSteps: steps), totalSlots)
  case .monthly:
    return (previewCumulativeChartData(throughSlot: 20, totalSlots: totalSlots, totalSteps: steps), totalSlots)
  case .yearly:
    return (previewCumulativeChartData(throughSlot: 8, totalSlots: totalSlots, totalSteps: steps), totalSlots)
  }
}

/// Daily preview data with realistic hourly patterns (matching watch widget).
private func previewDailyChartData(throughSlot lastSlot: Int, totalSteps: Int) -> [StepChartPoint] {
  let weights: [(slotRange: Range<Int>, weight: Double)] = [
    (0..<7, 0.0),
    (7..<8, 3.0),
    (8..<9, 8.0),
    (9..<12, 2.0),
    (12..<13, 7.0),
    (13..<17, 2.5),
    (17..<19, 6.0),
    (19..<21, 3.0),
    (21..<24, 0.5),
  ]

  var slotWeights = [Double]()
  for slot in 0..<lastSlot {
    let weight = weights.first(where: { $0.slotRange.contains(slot) })?.weight ?? 0
    slotWeights.append(weight)
  }

  let totalWeight = slotWeights.reduce(0, +)
  guard totalWeight > 0 else { return [StepChartPoint(slot: 0, cumulativeSteps: 0)] }

  var cumulative = 0
  var points = [StepChartPoint(slot: 0, cumulativeSteps: 0)]
  for (slot, weight) in slotWeights.enumerated() {
    let increment = Int((weight / totalWeight) * Double(totalSteps))
    cumulative += increment
    if cumulative > 0 {
      points.append(StepChartPoint(slot: slot, cumulativeSteps: cumulative))
    }
  }

  return points
}

/// Generic cumulative preview data for weekly/monthly/yearly.
private func previewCumulativeChartData(throughSlot lastSlot: Int, totalSlots: Int, totalSteps: Int) -> [StepChartPoint] {
  guard lastSlot > 0 else { return [StepChartPoint(slot: 0, cumulativeSteps: 0)] }

  let stepsPerSlot = totalSteps / lastSlot
  var points = [StepChartPoint(slot: 0, cumulativeSteps: 0)]

  for slot in 1...lastSlot {
    // Add some variance to make it look natural
    let variance = Double.random(in: 0.7...1.3)
    let slotSteps = Int(Double(stepsPerSlot) * variance)
    let cumulative = (points.last?.cumulativeSteps ?? 0) + slotSteps
    points.append(StepChartPoint(slot: slot, cumulativeSteps: cumulative))
  }

  return points
}
