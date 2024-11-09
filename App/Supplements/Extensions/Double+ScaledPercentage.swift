//
//  Double+ScaledPercentage.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import Foundation

extension Double {

    func scaledPercent(lower: Double, upper: Double) -> Double {
        if lower == upper {
            return self < lower ? 0 : 1
        }
        if lower < upper {
            let adjustedSelf = self - lower
            let adjustedUpper = upper - lower

            return min(max(adjustedSelf / adjustedUpper, 0.0), 1.0)
        } else {
            return 1 - scaledPercent(lower: upper, upper: lower)
        }
    }

    func invertedScaledPercent(lower: Double, upper: Double) -> Double {
        assert(lower < upper, "Incorrect arguments")

        let range = abs(upper - lower)

        if self < lower {
            return scaledPercent(lower: lower - range, upper: lower)
        } else if self > upper {
            return scaledPercent(lower: upper, upper: upper + range)
        }
        return 1
    }

    /// Scales the receiver between a score of -1 to 1 based on `lower` and `upper`.
    func scaledSymmetricalScore(lower: Double, upper: Double) -> Double {
        let percent = scaledPercent(lower: lower, upper: upper)
        return (percent * 2) - 1
    }
}
