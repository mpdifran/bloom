//
//  Double+ScaledPercentage.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import Foundation

extension Double {

    func scaledPercent(lower: Double, upper: Double) -> Double {
        guard lower < upper else { return 0 }

        let adjustedSelf = self - lower
        let adjustedUpper = upper - lower

        return min(max(adjustedSelf / adjustedUpper, 0.0), 1.0)
    }
}
