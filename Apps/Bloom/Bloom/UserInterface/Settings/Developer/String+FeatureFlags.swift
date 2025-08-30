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
    static let useSwiftUIChatView = "FeatureFlag.useSwiftUIChatView" // Toggle to use SwiftUI ChatView instead of default UIKit ChatViewController
  }
  
  enum ExperimentOverrideKey {
    static func key(for experimentId: String) -> String {
      return "ExperimentOverride.\(experimentId)"
    }
  }
}
