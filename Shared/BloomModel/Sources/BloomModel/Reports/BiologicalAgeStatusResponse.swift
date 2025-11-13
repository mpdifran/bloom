//
//  BiologicalAgeStatusResponse.swift
//  BloomModel
//
//  Created by Claude Code
//

import Foundation

public struct BiologicalAgeStatusResponse: Codable, Sendable {
    public let status: BiologicalAgeStatus
    public let result: BiologicalAgeResponse?
    public let errorMessage: String?

    public init(status: BiologicalAgeStatus, result: BiologicalAgeResponse?, errorMessage: String?) {
        self.status = status
        self.result = result
        self.errorMessage = errorMessage
    }
}
