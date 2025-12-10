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
