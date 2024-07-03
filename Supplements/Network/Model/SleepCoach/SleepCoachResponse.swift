//
//  SleepCoachResponse.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-03.
//

import Foundation

struct SleepCoachResponse: Codable {
    let activities: [SleepActivityModel]
    let chatMessages: [SleepChatMessage]?
}
