//
//  BowelMovement.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import SwiftData

@Model
final class BowelMovement: IdentifiableByDate, Sendable {
    let date: Date = Date.now
    let bristolStoolType: Int = 0
    let rawDuration: Int = 1

    init(
        date: Date = .now,
        bristolStoolType: Int = 0,
        duration: Duration = .between5And10Min
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

    var isValidBristolStoolType: Bool {
        bristolStoolType >= 1 && bristolStoolType <= 7
    }

    var bristolStoolTypeColor: Color {
        switch bristolStoolType {
        case 7: .pink
        case 1, 6: .yellow
        case 2, 5: .green
        case 3, 4: .coreSleep
        default: .clear
        }
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

        var scoreModifier: Double {
            switch self {
            case .lessThan5Min:
                0.9
            case .between5And10Min:
                1
            case .moreThan10Min:
                0.9
            }
        }
    }
}
