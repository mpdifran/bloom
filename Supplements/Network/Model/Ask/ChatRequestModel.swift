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

struct UserInfoModel: Codable {
    let age: Int?
    let sex: String?
    let bodyWeight: Double?
    let averageExerciseMin: QuantityModel?
}

struct QuantityModel: Codable {
    let amount: Double
    let kind: Kind
    let periodDays: Int?

    enum Kind: String, Codable {
        case latestValue
        case average
    }
}
