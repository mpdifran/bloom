//
//  OnboardingInfoResponse.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import Foundation

struct OnboardingInfoResponse: Codable {
    let name: String?
    let activities: [String]
    let supplements: [String]
    let healthGoals: [String]
}
