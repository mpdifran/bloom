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

  // MARK: - Mock Support

  #if DEBUG
  private static let mockBioAgeEnabledKey = "Debug.mockBioAgeEnabled"
  private static let mockBioAgeDeltaKey = "Debug.mockBioAgeDelta"

  public var mockBioAgeEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: Self.mockBioAgeEnabledKey) }
    set { UserDefaults.standard.set(newValue, forKey: Self.mockBioAgeEnabledKey) }
  }

  public var mockBioAgeDelta: Double {
    get { UserDefaults.standard.double(forKey: Self.mockBioAgeDeltaKey) }
    set { UserDefaults.standard.set(newValue, forKey: Self.mockBioAgeDeltaKey) }
  }

  /// Returns the bio age with mock delta applied if enabled in debug settings
  public var displayBiologicalAge: Double? {
    guard let biologicalAge else { return nil }
    guard mockBioAgeEnabled, let actualAge else { return biologicalAge }

    let mockedBioAge = actualAge + mockBioAgeDelta
    return max(actualAge - 12, min(actualAge + 12, mockedBioAge))
  }
  #else
  public var displayBiologicalAge: Double? { biologicalAge }
  #endif

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

  /// Metrics that have no data available
  public var missingMetrics: [BiologicalAgeMetric] {
    let availableMetrics = Set(metricContributions?.map(\.metric) ?? [])
    return BiologicalAgeMetric.allCases.filter { !availableMetrics.contains($0.rawValue) }
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

    // Listen for priority complication updates
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleComplicationUserInfo(_:)),
      name: WatchChannel.complicationUserInfoDidReceive,
      object: nil
    )
  }

  @objc private func handleComplicationUserInfo(_ notification: Notification) {
    // The WatchChannel already stored the data in UserDefaults and triggered widget refresh,
    // but we also want to update our in-memory state for the watch app UI
    guard let userInfo = notification.userInfo,
          userInfo[WatchChannel.biologicalAgeKey] != nil else {
      return
    }
    loadFromUserDefaults()
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
      metricContributions = try? JSONDecoder.watch.decode([WatchMetricContribution].self, from: contributionsData)
    }

    if let chartDataData = UserDefaults.group.data(forKey: Self.chartDataKey) {
      chartData = try? JSONDecoder.watch.decode([WatchBioAgeChartPoint].self, from: chartDataData)
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
    if let metricContributions, let data = try? JSONEncoder.watch.encode(metricContributions) {
      UserDefaults.group.set(data, forKey: Self.contributionsKey)
    }
    if let chartData, let data = try? JSONEncoder.watch.encode(chartData) {
      UserDefaults.group.set(data, forKey: Self.chartDataKey)
    }
  }

  @objc private func handleApplicationContextUpdate() {
    loadFromApplicationContext()
  }

  /// Loads biological age data from WatchConnectivity application context
  public func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.biologicalAgeKey),
          let watchData = try? JSONDecoder.watch.decode(WatchBiologicalAgeData.self, from: data) else {
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
