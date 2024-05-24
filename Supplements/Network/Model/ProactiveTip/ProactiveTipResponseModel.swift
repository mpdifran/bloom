//
//  ProactiveTipResponseModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation

struct ProactiveTipResponseModel: Codable {
    let message: String
    let recommendedActivities: [ActivityModel]?
}
