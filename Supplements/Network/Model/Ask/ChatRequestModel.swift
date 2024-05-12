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
    let bloodType: String?
    let bodyWeightPounds: QuantityModel?
    let dailyExerciseMinutes: QuantityModel?
    let dailySteps: QuantityModel?
    let dailyHeartRateVariability: QuantityModel?
    let restingHeartRate: [Double]
    let vO2Max: QuantityModel?
    let timeInDaylight: QuantityModel?
    let aggregateSleep: SleepAggregates?
}

struct QuantityModel: Codable, Equatable {
    let amount: Double
    let kind: Kind
    let unit: String
    let periodDays: Int?

    enum Kind: String, Codable {
        case latestValue
        case average
    }
}

struct SleepAggregates: Codable, Equatable {
    let remSleep: SleepStageAggregate
    let deepSleep: SleepStageAggregate
    let coreSleep: SleepStageAggregate
    let asleepTotal: SleepStageAggregate
    let awake: SleepStageAggregate
}

struct SleepStageAggregate: Codable, Equatable {
    let currentPeriodAmount: Double
    let previousPeriodAmount: Double
    let unit: String
    let periodDays: Int
    let kind: Kind

    enum Kind: String, Codable {
        case average
    }
}
