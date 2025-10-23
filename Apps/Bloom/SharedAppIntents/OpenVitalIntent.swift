//
//  OpenVitalIntent.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-23.
//

import AppIntents
import Foundation

struct OpenVitalIntent: AppIntent {
  static let title: LocalizedStringResource = "View Vital"
  static let description = IntentDescription("Opens a specific vital to view your health data.")
  static let openAppWhenRun: Bool = true

  @Parameter(title: "Vital")
  var vitalType: VitalType

  init(vitalType: VitalType) {
    self.vitalType = vitalType
  }

  init() {
    self.vitalType = .sleepQuality
  }

  func perform() async throws -> some IntentResult & OpensIntent {
    let urlString = "https://api.trybloom.app/\(vitalType.urlPath)"
    let url = URL(string: urlString)!
    return .result(opensIntent: OpenURLIntent(url))
  }
}
