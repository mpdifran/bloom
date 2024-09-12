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
        case stressLevels
        case nutrition
        case exerciseEffectiveness
        case cycleTracking
        case bowelMovements

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
            case .stressLevels:
                "Stress Levels"
            case .nutrition:
                "Nutrition"
            case .exerciseEffectiveness:
                "Exercise Effectiveness"
            case .cycleTracking:
                "Cycle Tracking"
            case .bowelMovements:
                "Bowel Movements"
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
            case .stressLevels:
                "bolt.fill"
            case .nutrition:
                "fork.knife"
            case .exerciseEffectiveness:
                "figure.mixed.cardio"
            case .cycleTracking:
                "circle.dotted.and.circle"
            case .bowelMovements:
                "toilet.fill"
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

    init(
        id: Kind,
        subtitle: String?,
        status: String?,
        score: Double,
        color: Color?,
        trend: Trend
    ) {
        self.id = id
        self.subtitle = subtitle ?? "No Data"
        self.status = status ?? "Unknown"
        self.score = status == nil ? 2 : score
        self.color = color ?? .gray
        self.trend = trend
    }

    init(id: Kind) {
        self.init(
            id: id,
            subtitle: nil,
            status: nil,
            score: 1,
            color: nil,
            trend: .noTrend
        )
    }
}
