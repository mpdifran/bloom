//
//  InsightsResponse.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import Foundation

struct InsightsResponse: Codable {
    let goalInsights: GoalInsights
    let scores: Scores
    let supplementInsights: SupplementInsights
    let userInfoInsights: UserInfoInsights
}

struct GoalInsights: Codable {
    let recommendedGoals: [String]
    let shortText: String
}

struct Scores: Codable {
    let rechargeScore: RechargeScore
    let takeChargeScore: TakeChargeScore
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

struct UserInfoInsights: Codable {

}
