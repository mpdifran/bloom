//
//  VitalModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI

public extension VitalModel {
    enum Kind: String, Hashable, Codable, CaseIterable, Sendable {
        case sleepQuality
        case activityLevel
        case heartHealth
        case bodyComposition
        case stressLevels
        case nutrition
        case exerciseEffectiveness
        case cycleTracking
        case bowelMovements

        public var name: String {
            switch self {
            case .sleepQuality:
                "Sleep Quality"
            case .activityLevel:
                "Activity Level"
            case .heartHealth:
                "Heart Health"
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

        public var systemImage: String {
            switch self {
            case .sleepQuality:
                "moon.zzz.fill"
            case .activityLevel:
                "figure.tennis"
            case .heartHealth:
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

    enum Level: Int, Hashable, Sendable {
        case low
        case medium
        case high
        case optimal
    }

    struct BarLevel: Hashable, Sendable {
        public let level: Level
        public let proportion: Double

        public init(
            level: Level,
            proportion: Double
        ) {
            self.level = level
            self.proportion = proportion
        }
    }
}

extension VitalModel.BarLevel: Comparable {
    public static func < (lhs: VitalModel.BarLevel, rhs: VitalModel.BarLevel) -> Bool {
        if lhs.level == rhs.level {
            return lhs.proportion < rhs.proportion
        }
        return lhs.level.rawValue < rhs.level.rawValue
    }
}

public struct VitalModel: Identifiable, Hashable, Sendable {
    public let id: Kind
    public let subtitle: String
    public let status: String
    public let score: Double
    public let color: Color
    public let barLevel: BarLevel?

    public init(
        id: Kind,
        subtitle: String?,
        status: String?,
        score: Double,
        color: Color?,
        barLevel: BarLevel?
    ) {
        self.id = id
        self.subtitle = subtitle ?? "No Data"
        self.status = status ?? "Unknown"
        self.score = status == nil ? 2 : score
        self.color = color ?? .gray
        self.barLevel = barLevel
    }

    public init(id: Kind) {
        self.init(
            id: id,
            subtitle: nil,
            status: nil,
            score: 1,
            color: nil,
            barLevel: nil
        )
    }
}
