//
//  OpenActionIntent.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-14.
//

import AppIntents
import Foundation

struct OpenActionIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Health Action"
  static let description = IntentDescription("Opens a health action to log data.")
  static let openAppWhenRun: Bool = true

  @Parameter(title: "Action Type")
  var actionType: ActionType

  init(actionType: ActionType) {
    self.actionType = actionType
  }

  init() {
    self.actionType = .logFood
  }

  func perform() async throws -> some IntentResult & OpensIntent {
    let urlString = "https://api.trybloom.app/\(actionType.urlPath)"
    let url = URL(string: urlString)!
    return .result(opensIntent: OpenURLIntent(url))
  }
}
