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
        subtitle: String,
        status: String,
        score: Double,
        color: Color,
        trend: Trend
    ) {
        self.id = id
        self.subtitle = subtitle
        self.status = status
        self.score = score
        self.color = color
        self.trend = trend
    }

    init(id: Kind) {
        self.init(
            id: id,
            subtitle: "No data available",
            status: "No Data",
            score: 1,
            color: .gray,
            trend: .noTrend
        )
    }
}
