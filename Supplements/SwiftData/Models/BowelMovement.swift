//
//  BowelMovement.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import Foundation
import SwiftData

@Model
final class BowelMovement: IdentifiableByDate {
    let date: Date
    let bristolStoolType: Int
    let rawDuration: Int

    init(
        date: Date,
        bristolStoolType: Int,
        duration: Duration
    ) {
        self.date = date
        self.bristolStoolType = bristolStoolType
        self.rawDuration = duration.rawValue
    }
}

extension BowelMovement {

    var duration: Duration {
        Duration(rawValue: rawDuration) ?? .between5And10Min
    }
}

extension BowelMovement {
    enum Duration: Int, CaseIterable, Identifiable {
        var id: Self { self }

        case lessThan5Min = 0
        case between5And10Min = 1
        case moreThan10Min = 2

        var name: String {
            switch self {
            case .lessThan5Min:
                "< 5 min"
            case .between5And10Min:
                "5 - 10 min"
            case .moreThan10Min:
                "> 10 min"
            }
        }
    }
}
