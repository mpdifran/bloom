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
    static let legacyGoalSetting = "FeatureFlag.legacyGoalSetting"
    static let bypassPaywall = "FeatureFlag.bypassPaywall"
    static let aiChat = "FeatureFlag.aiChat"
    static let alwaysShowReports = "FeatureFlag.alwaysShowReports"
  }
}
