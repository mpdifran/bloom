//
//  AskResponseModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation

struct AskResponseModel: Codable, Equatable {
    let message: String?
    let recommendedSupplements: [SupplementReccomendationModel]?
    let recommendedActivities: [ActivityModel]?
    let learnedUserFacts: [String]?
    let expiredUserFacts: [String]?
}
