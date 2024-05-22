//
//  AskRequestModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

struct AskRequestModel: Codable {
    let userInfo: UserInfoModel?
    let currentSupplements: [String]
    let currentGoals: [String]
    let chatHistory: [ChatMessageHistory]
    let learnedUserFacts: [String]
}

struct UserInfoModel: Codable, Equatable {
    let name: String?
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
    let activeEnergy: QuantityModel?
    let bodyFatPercentage: QuantityModel?
    let workouts: [WorkoutSummary]
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

struct WorkoutSummary: Codable, Equatable {
    let activity: String
    let startDate: Date
    let duration: TimeInterval
    let energyBurned: EnergyBurned
}

extension WorkoutSummary {
    struct EnergyBurned: Codable, Equatable {
        let value: Double
        let units: String
    }
}

struct ChatMessageHistory: Codable, Equatable {
    let role: Role
    let content: String
}

extension ChatMessageHistory {
    enum Role: String, Codable {
        case user
        case assistant
    }
}
