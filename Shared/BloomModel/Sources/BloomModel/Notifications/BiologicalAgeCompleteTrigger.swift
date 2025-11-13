//
//  BiologicalAgeCompleteTrigger.swift
//  BloomModel
//
//  Created by Claude Code
//

import Foundation

public struct BiologicalAgeCompleteTrigger: Codable, Sendable {
    public static let notificationType = "biological_age_complete"

    public let type: String

    public init() {
        self.type = Self.notificationType
    }
}
