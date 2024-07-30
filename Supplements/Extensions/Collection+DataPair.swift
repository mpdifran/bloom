//
//  Collection+DataPair.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-29.
//

import Foundation

extension Collection where Element == DataPair {

    func collated(by component: Calendar.Component) -> [Int : [DataPair]] {
        var collated = [Int : [DataPair]]()
        for pair in self {
            let value = Calendar.current.component(component, from: pair.date)
            collated[value, default: []].append(pair)
        }
        return collated
    }
}
