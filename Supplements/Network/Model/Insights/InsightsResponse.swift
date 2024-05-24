//
//  InsightsResponse.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct InsightsResponse: Codable {
    let userInfoInsights: [UserInfoInsight]
    let supplementInsights: SupplementInsights?
    let goalRecommendations: GoalInsights?
    let activityRecommendations: [ActivityModel]
    let scores: Scores?
}

struct UserInfoInsight: Codable {
    let name: String
    let range: Range
    let currentValue: Double
    let goalValue: Double
    let units: String
    let shortText: String
    let importance: Int

    enum Range: String, Codable {
        case below
        case above
    }

    var importanceSystemImageName: String {
        switch importance {
        case 5: "exclamationmark.octagon.fill"
        case 4, 3: "exclamationmark.triangle.fill"
        case 2, 1: "exclamationmark.circle.fill"
        default: "exclamationmark.circle.fill"
        }
    }

    var importanceColor: Color {
        switch importance {
        case 5: .red
        case 4, 3: .orange
        case 2, 1: .blue
        default: .blue
        }
    }
}

struct GoalInsights: Codable {
    let shortText: String
    let recommendedGoals: [String]
}

struct SupplementInsights: Codable {
    let recommendedSupplements: [RecommendedSupplement]
    let shortText: String
}

struct RecommendedSupplement: Codable {
    let supplementName: String
    let goal: String
    let efficacyRating: Int
    let recommendedDailyDose: String
}

struct Scores: Codable {
    let rechargeScore: RechargeScore?
    let takeChargeScore: TakeChargeScore?
}

struct NutrientsScore: Codable {
    let overallScore: Int?
    let supplementMatchToGoalScore: Int?
    let supplementScientificScore: Int?
}

struct RechargeScore: Codable {
    let hrvScore: Int?
    let meditationScore: Int?
    let overallScore: Int?
    let sleepScore: Int?
}

extension RechargeScore {

    var childScores: [InsightScoreCell.ChildScore] {
        var scores = [InsightScoreCell.ChildScore]()

        if let sleepScore {
            scores.append(.init(name: "Sleep Score", score: sleepScore))
        }
        if let meditationScore {
            scores.append(.init(name: "Meditation Score", score: meditationScore))
        }
        if let hrvScore {
            scores.append(.init(name: "HRV Score", score: hrvScore))
        }

        return scores
    }
}

struct TakeChargeScore: Codable {
    let exerciseScore: Int?
    let overallScore: Int?
    let vo2maxScore: Int?
}

extension TakeChargeScore {

    var childScores: [InsightScoreCell.ChildScore] {
        var scores = [InsightScoreCell.ChildScore]()

        if let exerciseScore {
            scores.append(.init(name: "Exercise Score", score: exerciseScore))
        }
        if let vo2maxScore {
            scores.append(.init(name: "VO2 Max Score", score: vo2maxScore))
        }

        return scores
    }
}
