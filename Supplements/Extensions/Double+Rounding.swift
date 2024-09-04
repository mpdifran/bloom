//
//  Double+Rounding.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-04.
//

import Foundation

extension Double {

    var numberOfDigits: Int {
        Int(Double.log10(self))
    }

    func roundedToNiceNumber() -> Self {
        let roundingPoint = Double.pow(10, numberOfDigits)
        return (self / roundingPoint).rounded() * roundingPoint
    }
}
