//
//  Comparable+Clipped.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-18.
//

import Foundation

extension Comparable {

    func clipped(_ min: Self, _ max: Self) -> Self {
        if self < min {
            return min
        }
        if self > max {
            return max
        }
        return self
    }
}
