//
//  InsightsRequest.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import Foundation

struct InsightsRequest: Codable {
    let userInfo: UserInfoModel?
    let currentSupplements: [String]
    let currentGoals: [String]
}
