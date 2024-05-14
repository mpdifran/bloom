//
//  InsightsResponse.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import Foundation

struct InsightsResponse: Codable {
    let tipOfTheDay: String?
    let goalsInsights: GoalInsights
    let scores: Scores
    let supplementInsights: SupplementInsights
    let userInfoInsights: [UserInfoInsight]
}

struct GoalInsights: Codable {
    let recommendedGoals: [String]
    let shortText: String
}

struct Scores: Codable {
    let nutrientsScore: NutrientsScore
    let rechargeScore: RechargeScore
    let takeChargeScore: TakeChargeScore
}

struct NutrientsScore: Codable {
    let overallScore: Int
    let supplementMatchToGoalScore: Int
    let supplementScientificScore: Int
    let shortText: String
}

struct RechargeScore: Codable {
    let hrvScore: Int
    let meditationScore: Int
    let overallScore: Int
    let sleepScore: Int
    let shortText: String
}

struct TakeChargeScore: Codable {
    let exerciseScore: Int
    let overallScore: Int
    let vo2maxScore: Int
    let shortText: String
}

struct SupplementInsights: Codable {
    let recommendedSupplements: [RecommendedSupplement]
    let shortText: String
}

struct RecommendedSupplement: Codable {
    let efficacyRating: Int
    let goal: String
    let recommendedDailyDose: String
    let supplementName: String
}

struct UserInfoInsight: Codable {
    let importance: Int
    let inRange: Int
    let metricName: String
    let shortText: String

    var inRangeBool: Bool {
        inRange == 1
    }
}
