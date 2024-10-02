//
//  Double+WithinRange.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-02.
//

import Foundation

public extension Double {

    func isWithinRange(of value: Double, precision: Double) -> Bool {
        let difference = abs(self - value) / value

        return difference <= precision
    }
}
