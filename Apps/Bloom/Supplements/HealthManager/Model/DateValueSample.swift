//
//  DateValueSample.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-04.
//

import Foundation

struct DateValueSample: Identifiable, Hashable, Sendable, Codable {
    var id: Int { hashValue }

    let date: Date
    let value: Double
}

