//
//  BiologicalAgeStatus.swift
//  BloomModel
//
//  Created by Claude Code
//

import Foundation

public enum BiologicalAgeStatus: String, Codable, Sendable {
    case pending
    case processing
    case completed
    case failed
    case notFound
}
