//
//  Set+OptionalInsert.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2024-06-03.
//

import Foundation

public extension Set {

    mutating func insert(_ optionalElement: Element?) {
        guard let element = optionalElement else { return }

        self.insert(element)
    }
}
