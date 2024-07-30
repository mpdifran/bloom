//
//  DataPair.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-29.
//

import Foundation

struct DataPair: Hashable, Identifiable {
    var id: Int { hashValue }

    let date: Date
    let a: Double
    let b: Double
}
