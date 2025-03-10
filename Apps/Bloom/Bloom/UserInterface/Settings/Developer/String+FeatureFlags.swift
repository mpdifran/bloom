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
    static let aiGoalSetting = "FeatureFlag.aiGoalSetting"
    static let alwaysAskForAIGoalSettingPermission = "FeatureFlag.alwaysAskForAIGoalSettingPermission"
    static let danieleMode = "PreferencesView.danieleMode"
  }
}
