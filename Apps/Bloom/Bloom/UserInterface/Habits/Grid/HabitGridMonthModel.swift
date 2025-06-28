//
//  HabitGridMonthModel.swift
//  Bloom
//
//  Created by Assistant on 2025-06-28.
//

import SwiftUI

struct HabitGridMonthModel: Hashable, Sendable {
    let months: [Month]
    
    init(months: [Month]) {
        self.months = months
    }
    
    init() {
        var months = [Month]()
        for index in 0 ..< 12 {
            months.insert(Month(id: index, isComplete: nil), at: 0)
        }
        self.months = months
    }
}

extension HabitGridMonthModel {
    struct Month: Identifiable, Hashable, Sendable {
        let id: Int
        let isComplete: Bool?
        let isCurrentMonth: Bool
        let referenceDate: Date
        let monthLabel: String
        
        init(
            id: Int,
            isComplete: Bool?,
            isCurrentMonth: Bool = false,
            referenceDate: Date = .now,
            monthLabel: String = ""
        ) {
            self.id = id
            self.isComplete = isComplete
            self.isCurrentMonth = isCurrentMonth
            self.referenceDate = referenceDate
            self.monthLabel = monthLabel
        }
    }
}