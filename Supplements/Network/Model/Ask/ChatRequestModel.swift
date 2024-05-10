//
//  ChatRequestModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

struct ChatRequestModel: Codable {
    let question: String
    let userInfo: UserInfoModel?
}

struct UserInfoModel: Codable, Equatable {
    let age: Int?
    let sex: String?
    let bodyWeightPounds: Double?
    let bloodType: String?
    let dailyExerciseMinutes: QuantityModel?
    let dailySteps: QuantityModel?
    let dailyHeartRateVariability: QuantityModel?
}

struct QuantityModel: Codable, Equatable {
    let amount: Double
    let kind: Kind
    let periodDays: Int?

    enum Kind: String, Codable {
        case latestValue
        case average
    }
}
