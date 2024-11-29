//
//  SleepCoachResponse.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-03.
//

import Foundation

struct SleepCoachResponse: Codable {
    let suggestions: [SleepSuggestionModel]
    let chatMessages: [SleepChatMessage]?
}
