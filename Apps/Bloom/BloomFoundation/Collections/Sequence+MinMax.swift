//
//  Sequence+MinMax.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-06.
//

import Foundation

public extension Sequence {

    func min<Compare: Comparable>(keyPath: KeyPath<Element, Compare>) -> Compare? {
        self.min(by: keyPath)?[keyPath: keyPath]
    }

    func min<Compare: Comparable>(by keyPath: KeyPath<Element, Compare>) -> Element? {
        self.min(by: { (lhs, rhs) in
            lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
        })
    }

    func max<Compare: Comparable>(keyPath: KeyPath<Element, Compare>) -> Compare? {
        self.max(by: keyPath)?[keyPath: keyPath]
    }

    func max<Compare: Comparable>(by keyPath: KeyPath<Element, Compare>) -> Element? {
        self.max(by: { (lhs, rhs) in
            lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
        })
    }
}
