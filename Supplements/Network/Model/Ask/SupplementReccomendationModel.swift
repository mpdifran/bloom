//
//  SupplementReccomendationModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import Foundation

struct SupplementReccomendationModel: Codable, Identifiable, Hashable {
    var id: Int { hashValue }

    let supplementName: String
    let efficacyRating: Int
    let recommendedDailyDose: String
    let goal: String
    let shortText: String
}
