//
//  Date+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-22.
//

import Foundation

extension Date {

    init(prevDays: Int) {
        self = Calendar.current.date(byAdding: .day, value: -prevDays, to: .now) ?? .now
    }
}
