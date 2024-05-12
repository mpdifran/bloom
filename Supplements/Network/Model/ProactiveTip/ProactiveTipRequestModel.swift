//
//  ProactiveTipRequestModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation

struct ProactiveTipRequestModel: Codable {
    let userInfo: UserInfoModel?
    let currentSupplements: [String]
    let currentGoals: [String]
    let chatHistory: [ChatMessageHistory]
}
