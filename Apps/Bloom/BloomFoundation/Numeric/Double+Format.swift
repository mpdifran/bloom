//
//  Double+Format.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-26.
//

import Foundation
import BloomFoundation

public extension Double {

    func format(using numberFormatter: NumberFormatter = .noDecimalPlaces) -> String {
        numberFormatter.string(from: self as NSNumber) ?? ""
    }
}
