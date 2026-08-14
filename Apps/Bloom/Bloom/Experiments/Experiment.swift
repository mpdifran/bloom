//
//  Experiment.swift
//  Bloom
//
//  Created by Claude on 2025-08-26.
//

import Foundation

enum ExperimentVariant: String, CaseIterable {
  case control
  case treatment
}

enum Experiment: String, CaseIterable, Identifiable {
  case standard

  var name: String {
    switch self {
    case .standard: String(localized: "Standard", comment: "Display name for experiment")
    }
  }

  var id: ExperimentIdentifier {
    ExperimentIdentifier(self.rawValue)
  }
}

extension ExperimentIdentifier {
  static let standard = Experiment.standard.id
}
