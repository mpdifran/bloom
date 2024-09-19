//
//  BowelMovement.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import SwiftData

extension SchemaV0 {
    @Model
    public final class BowelMovement: IdentifiableByDate {
        public var date: Date = Date.now
        public var bristolStoolType: Int = 0
        public var rawDuration: Int = 1

        public init(
            date: Date = .now,
            bristolStoolType: Int = 0,
            duration: Duration = .between5And10Min
        ) {
            self.date = date
            self.bristolStoolType = bristolStoolType
            self.rawDuration = duration.rawValue
        }
    }
}
