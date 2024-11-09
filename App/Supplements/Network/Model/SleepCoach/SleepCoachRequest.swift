//
//  SleepCoachRequest.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-02.
//

import Foundation

struct SleepCoachRequest: Codable {
    let userInfo: UserInfo
    let sleepHealthSnapshot: SleepHealthSnapshot
    let currentSuggestions: [SleepSuggestionModel]
    let chatHistory: [ChatMessageHistory]
}
