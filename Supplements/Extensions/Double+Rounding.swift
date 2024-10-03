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

        let magnitude = Double.log10(abs(self)).rounded(.down)
        let digits = Int(magnitude) + 1

        let roundingPoint: Double
        switch digits {
        case 1:
            roundingPoint = 1
        case 2:
            roundingPoint = 5
        case 3:
            roundingPoint = 10
        default:
            roundingPoint = Double.pow(10, magnitude - 1)
        }

        let scaled = (self / roundingPoint).rounded()  // Scale down and round
        return scaled * roundingPoint  // Scale it back up
    }
}
