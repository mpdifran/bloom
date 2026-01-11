//
//  MonitorSummaryCache.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import Foundation
import BloomModel

/// Actor responsible for caching and retrieving AI-generated monitor summaries.
/// Summaries are cached on state transition and persisted across app launches.
public actor MonitorSummaryCache {

  public static let shared = MonitorSummaryCache()

  private let userDefaults = UserDefaults.standard
  private let cacheKey = "monitor.summary.cache"
  private let timestampKey = "monitor.summary.timestamp"

  /// Maximum age for a cached summary (7 days)
  private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60

  private init() {}

  // MARK: - Public API

  /// Cache a monitor summary after a state transition.
  /// - Parameter summary: The AI-generated summary to cache
  public func cache(_ summary: MonitorSummaryResponse) async {
    do {
      let data = try JSONEncoder().encode(summary)
      userDefaults.set(data, forKey: cacheKey)
      userDefaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
      print("MonitorSummaryCache: Cached summary successfully")
    } catch {
      print("MonitorSummaryCache: Failed to cache summary: \(error)")
    }
  }

  /// Get the cached summary if available and not expired.
  /// - Returns: The cached summary, or nil if not found or expired
  public func getCachedSummary() async -> MonitorSummaryResponse? {
    // Check if cache exists
    guard let data = userDefaults.data(forKey: cacheKey) else {
      return nil
    }

    // Check if cache is expired
    let timestamp = userDefaults.double(forKey: timestampKey)
    let cacheAge = Date().timeIntervalSince1970 - timestamp
    if cacheAge > maxCacheAge {
      await clearCache()
      return nil
    }

    // Decode and return
    do {
      let summary = try JSONDecoder().decode(MonitorSummaryResponse.self, from: data)
      return summary
    } catch {
      print("MonitorSummaryCache: Failed to decode cached summary: \(error)")
      await clearCache()
      return nil
    }
  }

  /// Clear the cached summary (called when state returns to Good).
  public func clearCache() async {
    userDefaults.removeObject(forKey: cacheKey)
    userDefaults.removeObject(forKey: timestampKey)
    print("MonitorSummaryCache: Cleared cache")
  }

  /// Check if a cached summary exists and is valid.
  public func hasCachedSummary() async -> Bool {
    await getCachedSummary() != nil
  }
}
