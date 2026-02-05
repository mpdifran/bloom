//
//  String+FeatureFlags.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-28.
//

import Foundation

extension String {
  enum FeatureFlag {
    static let developerMode = "FeatureFlag.developerMode"
    static let bypassPaywall = "FeatureFlag.bypassPaywall"
    static let enableOpenAIModelOverride = "FeatureFlag.enableOpenAIModelOverride"
    static let mockMagicScanner = "FeatureFlag.mockMagicScanner"
    static let reEngagementTestMode = "FeatureFlag.reEngagementTestMode"
    static let showTrendsTab = "FeatureFlag.showTrendsTab"
    static let mockBioAgeEnabled = "FeatureFlag.mockBioAgeEnabled"
    static let mockBioAgeDelta = "FeatureFlag.mockBioAgeDelta"
  }
  
  enum ExperimentOverrideKey {
    static func key(for experimentId: String) -> String {
      return "ExperimentOverride.\(experimentId)"
    }
  }

  enum SaleOverrideKey {
    static let overriddenSaleId = "SaleOverride.overriddenSaleId"
    static let alwaysShowOnForeground = "SaleOverride.alwaysShowOnForeground"
  }
}
