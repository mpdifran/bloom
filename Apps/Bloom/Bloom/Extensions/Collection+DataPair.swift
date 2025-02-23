//
//  Collection+DataPair.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-29.
//

import Foundation
import DataContainer

extension Collection where Element: IdentifiableByDate {

    func collated(by component: Calendar.Component) -> [Int: [Element]] {
        var collated = [Int: [Element]]()
        for pair in self {
            let value = Calendar.current.component(component, from: pair.date)
            collated[value, default: []].append(pair)
        }
        return collated
    }
}
