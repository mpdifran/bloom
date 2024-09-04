//
//  Double+Rounding.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-04.
//

import Foundation

extension Double {

    func roundedToNiceNumber() -> Self {
        guard abs(self) > 0 else { return 0 }

        let roundingPoint = Double.pow(10, Double.log10(self))
        return (self / roundingPoint).rounded() * roundingPoint
    }
}
