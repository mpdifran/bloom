//
//  VitalModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI

extension VitalModel {
    enum Kind: String, Hashable, Codable, CaseIterable {
        case sleepQuality
        case activityLevel
        case cardioFitness
        case bodyComposition
//        case mobility
        case stressLevels
        case nutrition
        case exerciseEffectiveness

        var name: String {
            switch self {
            case .sleepQuality:
                "Sleep Quality"
            case .activityLevel:
                "Activity Level"
            case .cardioFitness:
                "Cardio Fitness"
            case .bodyComposition:
                "Body Composition"
//            case .mobility:
//                "Mobility"
            case .stressLevels:
                "Stress Levels"
            case .nutrition:
                "Nutrition"
            case .exerciseEffectiveness:
                "Exercise Effectiveness"
            }
        }

        var systemImage: String {
            switch self {
            case .sleepQuality:
                "moon.zzz.fill"
            case .activityLevel:
                "figure.tennis"
            case .cardioFitness:
                "heart.fill"
            case .bodyComposition:
                "gauge.with.needle"
//            case .mobility:
//                "figure.walk"
            case .stressLevels:
                "bolt.fill"
            case .nutrition:
                "fork.knife"
            case .exerciseEffectiveness:
                "figure.mixed.cardio"
            }
        }
    }

    enum Trend {
        case increasing
        case decreasing
        case noTrend
    }
}

struct VitalModel: Identifiable, Hashable {
    let id: Kind
    let subtitle: String
    let status: String
    let score: Double
    let color: Color
    let trend: Trend
}
