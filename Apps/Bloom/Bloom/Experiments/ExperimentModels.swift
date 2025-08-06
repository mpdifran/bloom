//
//  ExperimentModels.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-05.
//

import Foundation

enum ExperimentVariant: String, CaseIterable {
    case control
    case treatment
}

struct Experiment {
    let id: String
    let name: String
    let isEnabled: Bool
    let treatmentPercentage: Double // 0.0 to 1.0
    
    init(id: String, name: String, isEnabled: Bool = true, treatmentPercentage: Double = 0.5) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.treatmentPercentage = treatmentPercentage
    }
}