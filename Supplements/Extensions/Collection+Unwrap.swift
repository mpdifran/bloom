//
//  Collection+Unwrap.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-11.
//

import Foundation

extension Collection {

    func unwrap<ElementOfResult>() -> [ElementOfResult] where Element == Optional<ElementOfResult> {
        compactMap({ $0 })
    }
}
