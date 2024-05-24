//
//  ChatMessage.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

struct ChatMessage: Identifiable, Hashable, Equatable {
    let id = UUID().uuidString
    let message: String?
    let timestamp: Date
    let supplementReccomendation: [SupplementReccomendationModel]
    let activityRecommendation: [ActivityModel]
    let isCurrentUser: Bool

    init(
        message: String?,
        timestamp: Date,
        supplementReccomendation: [SupplementReccomendationModel] = [],
        activityRecommendation: [ActivityModel] = [],
        isCurrentUser: Bool
    ) {
        self.message = message
        self.timestamp = timestamp
        self.supplementReccomendation = supplementReccomendation
        self.activityRecommendation = activityRecommendation
        self.isCurrentUser = isCurrentUser
    }
}
