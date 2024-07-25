//
//  Double+ScaledPercentage.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import Foundation

extension Double {

    func scaledPercent(lower: Double, upper: Double) -> Double {
        if lower < upper {
            let adjustedSelf = self - lower
            let adjustedUpper = upper - lower

            return min(max(adjustedSelf / adjustedUpper, 0.0), 1.0)
        } else {
            return 1 - scaledPercent(lower: upper, upper: lower)
        }
    }
}
