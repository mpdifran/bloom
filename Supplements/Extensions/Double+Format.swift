//
//  Double+Format.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-26.
//

import Foundation
import BloomFoundation

extension Double {

    func format(to decimalPlaces: Int = 0) -> String {
        if decimalPlaces > 0 {
            return NumberFormatter.oneDecimalPlace.string(from: self as NSNumber) ?? ""
        }

        return NumberFormatter.noDecimalPlaces.string(from: self as NSNumber) ?? ""
    }
}
