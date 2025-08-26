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

enum Experiment: String, CaseIterable {
    case softerHealthKitView = "softer_healthkit_view"
    
    var name: String {
        switch self {
        case .softerHealthKitView:
            return "Softer HealthKit View"
        }
    }
    
    var id: ExperimentIdentifier {
        ExperimentIdentifier(self.rawValue)
    }
}

extension ExperimentIdentifier {
    static let softerHealthKitView = Experiment.softerHealthKitView.id
}