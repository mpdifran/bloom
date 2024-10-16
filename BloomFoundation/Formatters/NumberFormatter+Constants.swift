//
//  NumberFormatter+Constants.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2024-08-21.
//

import Foundation

public extension NumberFormatter {

    static let noDecimalPlaces = NumberFormatter().with {
        $0.maximumFractionDigits = 0
        $0.numberStyle = .decimal
    }

    static let oneDecimalPlace = NumberFormatter().with {
        $0.maximumFractionDigits = 1
        $0.numberStyle = .decimal
    }

    static let twoDecimalPlaces = NumberFormatter().with {
        $0.maximumFractionDigits = 2
        $0.numberStyle = .decimal
    }
}
