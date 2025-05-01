//
//  Collection+Unwrap.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-11.
//

import Foundation

public extension Collection {

    func unwrap<ElementOfResult>() -> [ElementOfResult] where Element == Optional<ElementOfResult> {
        compactMap({ $0 })
    }
}
