//
//  Sequence+MinMax.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-06.
//

import Foundation

extension Sequence {
    
    func min<Compare: Comparable>(keyPath: KeyPath<Element, Compare>) -> Compare? {
        self.min(by: { (lhs, rhs) in
            lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
        })?[keyPath: keyPath]
    }

    func max<Compare: Comparable>(keyPath: KeyPath<Element, Compare>) -> Compare? {
        self.max(by: { (lhs, rhs) in
            lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
        })?[keyPath: keyPath]
    }
}
