//
//  BiologicalAgeUploadRequest.swift
//  BloomModel
//
//  Created by Claude Code
//

import Foundation

public struct BiologicalAgeUploadRequest: Codable, Sendable {
    public let healthContext: String
    public let currentAge: Int?
    public let lastBiologicalAge: Double?

    public init(healthContext: String, currentAge: Int?, lastBiologicalAge: Double?) {
        self.healthContext = healthContext
        self.currentAge = currentAge
        self.lastBiologicalAge = lastBiologicalAge
    }
}
