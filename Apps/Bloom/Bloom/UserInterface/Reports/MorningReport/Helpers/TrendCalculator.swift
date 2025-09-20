//
//  TrendCalculator.swift
//  Bloom
//
//  Created by Assistant on 2025-01-25.
//

import Foundation
import HealthKit

struct TrendCalculator {

  /// Calculate trend from HKQuantity samples
  static func calculateTrend(
    current: Double,
    previous: [HKQuantitySample],
    unit: HKUnit,
    lowerIsBetter: Bool = false
  ) -> MetricWithTrend.Trend? {
    guard !previous.isEmpty else { return nil }

    let previousValues = previous.map { $0.quantity.doubleValue(for: unit) }
    let previousAverage = previousValues.reduce(0, +) / Double(previousValues.count)

    let percentChange = ((current - previousAverage) / previousAverage) * 100

    if abs(percentChange) < 5 {
      return .stable
    } else {
      let isIncreasing = percentChange > 0
      if lowerIsBetter {
        return isIncreasing ? .decreasing : .increasing
      } else {
        return isIncreasing ? .increasing : .decreasing
      }
    }
  }

  /// Calculate trend from raw double values
  static func calculateTrend(
    current: Double,
    previous: [Double],
    lowerIsBetter: Bool = false
  ) -> MetricWithTrend.Trend? {
    guard !previous.isEmpty else { return nil }

    let previousAverage = previous.reduce(0, +) / Double(previous.count)

    // Avoid division by zero
    guard previousAverage != 0 else {
      return current > 0 ? .increasing : .stable
    }

    let percentChange = ((current - previousAverage) / previousAverage) * 100

    if abs(percentChange) < 5 {
      return .stable
    } else {
      let isIncreasing = percentChange > 0
      if lowerIsBetter {
        return isIncreasing ? .decreasing : .increasing
      } else {
        return isIncreasing ? .increasing : .decreasing
      }
    }
  }

  /// Calculate trend from integer values
  static func calculateTrend(
    current: Int,
    previous: [Int],
    lowerIsBetter: Bool = false
  ) -> MetricWithTrend.Trend? {
    let currentDouble = Double(current)
    let previousDouble = previous.map { Double($0) }
    return calculateTrend(current: currentDouble, previous: previousDouble, lowerIsBetter: lowerIsBetter)
  }
}