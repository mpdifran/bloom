//
//  Collection+Sort.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import Foundation

extension Collection {

    func sorted<SortProperty>(keyPath: KeyPath<Element, SortProperty>) -> [Self.Element] where SortProperty: Comparable {
        sorted { lhs, rhs in
            lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
        }
    }
}
