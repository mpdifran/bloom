//
//  BiologicalAgeUploadResponse.swift
//  BloomModel
//
//  Created by Claude Code
//

import Foundation

public struct BiologicalAgeUploadResponse: Codable, Sendable {
    public let status: BiologicalAgeStatus

    public init(status: BiologicalAgeStatus) {
        self.status = status
    }
}
