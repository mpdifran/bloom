//
//  Double+Format.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-26.
//

import Foundation

extension Double {

    func format(to decimalPlaces: Int = 0) -> String {
        String(format: "%.\(decimalPlaces)f", self)
    }
}
