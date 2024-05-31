//
//  Collection+Average.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import Foundation

enum CollectionAverageSubsequence {
    case prefix(Int)
    case suffix(Int)
}

extension Collection {

    func average(keyPath: KeyPath<Element, Double>, subsequence: CollectionAverageSubsequence? = nil) -> Double {
        let items: Array<Element>
        switch subsequence {
        case .prefix(let prefix):
            items = Array(self.prefix(prefix))
        case .suffix(let suffix):
            items = Array(self.suffix(suffix))
        default:
            items = Array(self)
        }
        let sum = items.reduce(0) { total, element in
            total + element[keyPath: keyPath]
        }
        return sum / Double(items.count)
    }
}
