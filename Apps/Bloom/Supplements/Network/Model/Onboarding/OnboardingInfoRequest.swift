//
//  OnboardingInfoRequest.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import Foundation

struct OnboardingInfoRequest: Codable {
    let chatHistory: [ChatMessageHistory]
}
