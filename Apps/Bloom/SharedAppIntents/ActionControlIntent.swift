//
//  ActionControlIntent.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-14.
//

import AppIntents
import Foundation

struct ActionControlIntent: ControlConfigurationIntent {
  static let title: LocalizedStringResource = "Health Action Configuration"
  static let description = IntentDescription("Choose which health action to perform.")

  @Parameter(title: "Action", default: .scanFood)
  var actionType: ActionType
}
