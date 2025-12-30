//
//  YouSettings.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import Foundation
import DataContainer

struct YouSettings: Codable, Equatable {
  var sectionOrder: [VitalModel.Kind]

  static var defaultOrder: [VitalModel.Kind] {
    [
      .sleepQuality,
      .activityLevel,
      .heartHealth,
      .bodyComposition,
      .stressLevels,
      .nutrition,
      .exerciseEffectiveness,
      .cycleTracking,
      .bowelMovements
    ]
  }

  init() {
    self.sectionOrder = Self.defaultOrder
  }

  init(sectionOrder: [VitalModel.Kind]) {
    self.sectionOrder = sectionOrder
  }
}
