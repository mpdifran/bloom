//
//  MonitorInsightManager.swift
//  Bloom
//
//  Created by Claude on 2026-01-19.
//

import Foundation
import SwiftUI
import BloomModel
import BloomUI
import TelemetryDeck
import CoreNetwork

private extension String {
  static func cachedInsightKey(for monitorType: MonitorType) -> String {
    "MonitorInsightManager.cachedInsight.\(monitorType.rawValue)"
  }
}

/// Manages AI-generated insights for monitor detail views.
/// Caches insights per calendar day and invalidates when monitor state changes.
@MainActor @Observable
final class MonitorInsightManager {
  static let shared = MonitorInsightManager()

  /// Loading state per monitor type
  private(set) var loadingStates: [MonitorType: Bool] = [:]

  /// Error state per monitor type
  private(set) var errorStates: [MonitorType: Bool] = [:]

  /// Cached insights per monitor type (in-memory + UserDefaults)
  private var cachedInsights: [MonitorType: CachedInsight] = [:]

  private init() {
    loadAllCachedInsights()
  }

  // MARK: - Public API

  func insight(for monitorType: MonitorType) -> MonitorInsightResponse? {
    guard AIFeatureSettings.shared.monitorEnabled else { return nil }
    guard let cached = cachedInsights[monitorType] else { return nil }
    return cached.response
  }

  func isLoading(for monitorType: MonitorType) -> Bool {
    loadingStates[monitorType] ?? false
  }

  func hasError(for monitorType: MonitorType) -> Bool {
    errorStates[monitorType] ?? false
  }

  /// Load insight if cache is invalid or monitor state changed
  func loadInsightIfNeeded(
    for monitorType: MonitorType,
    currentResult: MonitorResult
  ) async {
    guard AIFeatureSettings.shared.monitorEnabled else { return }
    guard EntitlementController.shared.hasBloomPro == true else { return }
    guard !isLoading(for: monitorType) else { return }

    // Check if cache is still valid: same state AND same calendar day
    if let cached = cachedInsights[monitorType],
       cached.monitorState == currentResult.state,
       Calendar.current.isDate(cached.timestamp, inSameDayAs: Date()) {
      return // Cache is valid, no refresh needed
    }

    await loadInsight(for: monitorType, currentResult: currentResult)
  }

  /// Force refresh insight
  func refreshInsight(
    for monitorType: MonitorType,
    currentResult: MonitorResult
  ) async {
    guard AIFeatureSettings.shared.monitorEnabled else { return }
    guard EntitlementController.shared.hasBloomPro == true else { return }

    clearCache(for: monitorType)
    await loadInsight(for: monitorType, currentResult: currentResult)
  }

  // MARK: - Private

  private func loadInsight(
    for monitorType: MonitorType,
    currentResult: MonitorResult
  ) async {
    // Check if required categories are enabled - skip entirely if not
    // to prevent leaking health data in the monitorContext
    let enabledCategories = AIDataSharingSettings.shared.enabledCategories
    let required = requiredCategories(for: monitorType)
    guard required.isSubset(of: enabledCategories) else {
      return
    }

    loadingStates[monitorType] = true
    errorStates[monitorType] = false

    defer {
      loadingStates[monitorType] = false
    }

    do {
      // Generate monitor context (MonitorResult as JSON)
      let monitorContext = try JSONEncoder.bloomModel.encode(currentResult)
      let monitorContextString = String(data: monitorContext, encoding: .utf8) ?? "{}"

      // Generate health context based on monitor type
      let healthContext = try await generateHealthContext(for: monitorType)

      let request = MonitorInsightRequest(
        monitorType: monitorType.rawValue,
        monitorContext: monitorContextString,
        healthContext: healthContext,
        timezone: TimeZone.current.identifier
      )

      let urlRequest = try await URLRequest.Monitor.getInsight(body: request)
      let response = try await URLSession.shared.authenticatedBloomRequestWithResponse(
        request: urlRequest,
        responseType: MonitorInsightResponse.self
      )

      // Cache the response
      let cached = CachedInsight(
        response: response,
        timestamp: Date(),
        monitorState: currentResult.state
      )
      cachedInsights[monitorType] = cached
      saveCachedInsight(cached, for: monitorType)

    } catch {
      errorStates[monitorType] = true
      TelemetryDeck.errorOccurred(
        id: "MonitorInsightManager.loadInsight",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }

  private func generateHealthContext(for monitorType: MonitorType) async throws -> String {
    let enabledCategories = AIDataSharingSettings.shared.enabledCategories
    let relevantCategories = requiredCategories(for: monitorType)

    // Only include categories that are both relevant AND enabled
    let activeCategories = relevantCategories.intersection(enabledCategories)

    guard !activeCategories.isEmpty else {
      return "{}" // No data to share
    }

    // Use ChatVitalConverter to generate health data filtered by categories
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    guard let healthData = await ChatVitalConverter.shared.convertHealthData(
      from: startDate,
      enabledCategories: activeCategories
    ) else {
      return "{}"
    }

    let data = try JSONEncoder.bloomModel.encode(healthData)
    return String(data: data, encoding: .utf8) ?? "{}"
  }

  private func requiredCategories(for monitorType: MonitorType) -> Set<AIHealthCategory> {
    switch monitorType {
    case .sleep:
      return [.sleep, .physicalActivity]
    case .recovery:
      return [.bodyMetrics, .physicalActivity]
    case .stress:
      return [.physicalActivity, .bodyMetrics, .mentalWellness]
    }
  }

  private func clearCache(for monitorType: MonitorType) {
    cachedInsights[monitorType] = nil
    UserDefaults.standard.removeObject(forKey: .cachedInsightKey(for: monitorType))
  }

  // MARK: - Persistence

  private func loadAllCachedInsights() {
    for monitorType in MonitorType.allCases {
      if let data = UserDefaults.standard.data(forKey: .cachedInsightKey(for: monitorType)),
         let cached = try? JSONDecoder().decode(CachedInsight.self, from: data) {
        cachedInsights[monitorType] = cached
      }
    }
  }

  private func saveCachedInsight(_ cached: CachedInsight, for monitorType: MonitorType) {
    if let data = try? JSONEncoder().encode(cached) {
      UserDefaults.standard.set(data, forKey: .cachedInsightKey(for: monitorType))
    }
  }
}

// MARK: - Cache Model

private struct CachedInsight: Codable {
  let response: MonitorInsightResponse
  let timestamp: Date
  let monitorState: MonitorStateValue
}
