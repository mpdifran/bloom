//
//  Double+Interpolation.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-02.
//

import Foundation

public extension Double {

    func interpolated(with otherValue: Double, interpolation: Double = 0.5) -> Double {
        let difference = otherValue - self
        return self + difference * interpolation
    }
}
