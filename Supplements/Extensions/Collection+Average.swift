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
        
        guard items.isNotEmpty else { return 0 }

        let sum = items.reduce(0) { total, element in
            total + element[keyPath: keyPath]
        }
        return sum / Double(items.count)
    }

    func variance(keyPath: KeyPath<Element, Double>, subsequence: CollectionAverageSubsequence? = nil) -> Double? {
        let items: Array<Element>
        switch subsequence {
        case .prefix(let prefix):
            items = Array(self.prefix(prefix))
        case .suffix(let suffix):
            items = Array(self.suffix(suffix))
        default:
            items = Array(self)
        }

        guard items.isNotEmpty else { return nil }

        let mean = average(keyPath: keyPath, subsequence: subsequence)
        let sumOfSquaredDifferences = items.map { pow($0[keyPath: keyPath] - mean, 2) }.reduce(0, +)

        return sumOfSquaredDifferences / Double(items.count)
    }

    func standardDeviation(keyPath: KeyPath<Element, Double>, subsequence: CollectionAverageSubsequence? = nil) -> Double? {
        guard let variance = variance(keyPath: keyPath, subsequence: subsequence) else { return nil }

        return sqrt(variance)
    }

    func sum(keyPath: KeyPath<Element, Double>, subsequence: CollectionAverageSubsequence? = nil) -> Double {
        let items: Array<Element>
        switch subsequence {
        case .prefix(let prefix):
            items = Array(self.prefix(prefix))
        case .suffix(let suffix):
            items = Array(self.suffix(suffix))
        default:
            items = Array(self)
        }

        return items.reduce(0) { $0 + $1[keyPath: keyPath] }
    }

    func sum(where addend: (Element) -> Double) -> Double {
        reduce(0) { (partialResult, element) in
            partialResult + addend(element)
        }
    }

    func group(by matcher: (Element, Element) -> Bool) -> [[Element]] {
        guard isNotEmpty else { return [] }

        var rootResult = [[Element]]()

        var iterator = makeIterator()
        var currentGroup = [iterator.next()!]

        while let element = iterator.next() {
            if matcher(currentGroup.last!, element) {
                currentGroup.append(element)
            } else {
                rootResult.append(currentGroup)
                currentGroup = [element]
            }
        }

        rootResult.append(currentGroup)

        return rootResult
    }
}
