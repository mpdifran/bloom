//
//  NumberFormatter+Constants.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2024-08-21.
//

import Foundation

public extension NumberFormatter {

    static var noDecimalPlaces: NumberFormatter = {
        let numberFormatter = NumberFormatter()

        numberFormatter.maximumFractionDigits = 0
        numberFormatter.numberStyle = .decimal

        return numberFormatter
    }()

    static var oneDecimalPlace: NumberFormatter = {
        let numberFormatter = NumberFormatter()

        numberFormatter.maximumFractionDigits = 1
        numberFormatter.numberStyle = .decimal

        return numberFormatter
    }()

    static var twoDecimalPlaces: NumberFormatter = {
        let numberFormatter = NumberFormatter()

        numberFormatter.maximumFractionDigits = 2
        numberFormatter.numberStyle = .decimal

        return numberFormatter
    }()
}
