//
//  BiologicalAgeProvider.swift
//  CoreHealth
//
//  Created by Claude on 2026-01-26.
//

import Foundation
import BloomFoundation

#if os(watchOS)
/// Provides biological age data on watchOS by reading from WatchConnectivity application context.
@Observable @MainActor
public final class BiologicalAgeProvider {
  public static let shared = BiologicalAgeProvider()

  private static let biologicalAgeKey = "BiologicalAgeProvider.biologicalAge"
  private static let actualAgeKey = "BiologicalAgeProvider.actualAge"
  private static let lastCalculatedKey = "BiologicalAgeProvider.lastCalculated"
  private static let confidenceKey = "BiologicalAgeProvider.confidence"
  private static let contributionsKey = "BiologicalAgeProvider.contributions"
  private static let chartDataKey = "BiologicalAgeProvider.chartData"

  public private(set) var biologicalAge: Double? {
    didSet { saveToUserDefaults() }
  }
  public private(set) var actualAge: Double? {
    didSet { saveToUserDefaults() }
  }
  public private(set) var lastCalculated: Date? {
    didSet { saveToUserDefaults() }
  }
  public private(set) var confidence: WatchBioAgeConfidence? {
    didSet { saveToUserDefaults() }
  }
  public private(set) var metricContributions: [WatchMetricContribution]? {
    didSet { saveToUserDefaults() }
  }
  public private(set) var chartData: [WatchBioAgeChartPoint]? {
    didSet { saveToUserDefaults() }
  }

  /// Use synced actualAge - HealthDefaults uses UserDefaults which is not available on watchOS
  public var chronologicalAge: Double {
    actualAge ?? 0
  }

  /// Metrics that are making the user younger (negative weighted delta)
  public var positiveFactors: [WatchMetricContribution] {
    metricContributions?.filter(\.isPositive).sorted { $0.weightedDelta < $1.weightedDelta } ?? []
  }

  /// Metrics that are making the user older (positive weighted delta)
  public var negativeFactors: [WatchMetricContribution] {
    metricContributions?.filter(\.isNegative).sorted { $0.weightedDelta > $1.weightedDelta } ?? []
  }

  /// Metrics with minimal effect
  public var neutralFactors: [WatchMetricContribution] {
    metricContributions?.filter(\.isNeutral) ?? []
  }

  /// Number of metrics considered
  public var metricsCount: Int {
    metricContributions?.count ?? 0
  }

  private init() {
    loadFromUserDefaults()
    loadFromApplicationContext()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleApplicationContextUpdate),
      name: WatchChannel.applicationContextDidUpdate,
      object: nil
    )
  }

  private func loadFromUserDefaults() {
    biologicalAge = UserDefaults.group.object(forKey: Self.biologicalAgeKey) as? Double
    actualAge = UserDefaults.group.object(forKey: Self.actualAgeKey) as? Double

    if let timestamp = UserDefaults.group.object(forKey: Self.lastCalculatedKey) as? Double {
      lastCalculated = Date(timeIntervalSince1970: timestamp)
    }

    if let confidenceRaw = UserDefaults.group.string(forKey: Self.confidenceKey) {
      confidence = WatchBioAgeConfidence(rawValue: confidenceRaw)
    }

    if let contributionsData = UserDefaults.group.data(forKey: Self.contributionsKey) {
      metricContributions = try? JSONDecoder().decode([WatchMetricContribution].self, from: contributionsData)
    }

    if let chartDataData = UserDefaults.group.data(forKey: Self.chartDataKey) {
      chartData = try? JSONDecoder().decode([WatchBioAgeChartPoint].self, from: chartDataData)
    }
  }

  private func saveToUserDefaults() {
    if let biologicalAge {
      UserDefaults.group.set(biologicalAge, forKey: Self.biologicalAgeKey)
    }
    if let actualAge {
      UserDefaults.group.set(actualAge, forKey: Self.actualAgeKey)
    }
    if let lastCalculated {
      UserDefaults.group.set(lastCalculated.timeIntervalSince1970, forKey: Self.lastCalculatedKey)
    }
    if let confidence {
      UserDefaults.group.set(confidence.rawValue, forKey: Self.confidenceKey)
    }
    if let metricContributions, let data = try? JSONEncoder().encode(metricContributions) {
      UserDefaults.group.set(data, forKey: Self.contributionsKey)
    }
    if let chartData, let data = try? JSONEncoder().encode(chartData) {
      UserDefaults.group.set(data, forKey: Self.chartDataKey)
    }
  }

  @objc private func handleApplicationContextUpdate() {
    loadFromApplicationContext()
  }

  /// Loads biological age data from WatchConnectivity application context
  public func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.biologicalAgeKey),
          let watchData = try? JSONDecoder().decode(WatchBiologicalAgeData.self, from: data) else {
      return
    }

    let hasNewData = biologicalAge != watchData.biologicalAge || actualAge != watchData.actualAge

    biologicalAge = watchData.biologicalAge
    actualAge = watchData.actualAge
    lastCalculated = watchData.lastCalculated
    confidence = watchData.confidence
    metricContributions = watchData.metricContributions
    chartData = watchData.chartData

    // Refresh the widget timeline if data changed
    if hasNewData {
      WidgetRefreshManager.shared.reloadBiologicalAgeWidget()
    }
  }
}
#endif
