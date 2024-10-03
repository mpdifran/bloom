//
//  BowelMovement+DTO.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-03.
//

import Foundation
import SwiftData

public struct BowelMovementDTO: Sendable, Identifiable {
    public let id: PersistentIdentifier
    public var date: Date = Date.now
    public var bristolStoolType: Int = 0
    public var duration: BowelMovement.Duration
}

public extension BowelMovement {

    func asDTO() -> BowelMovementDTO {
        BowelMovementDTO(
            id: persistentModelID,
            date: date,
            bristolStoolType: bristolStoolType,
            duration: duration
        )
    }
}
