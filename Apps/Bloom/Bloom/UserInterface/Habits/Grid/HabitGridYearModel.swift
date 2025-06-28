//
//  HabitGridYearModel.swift
//  Bloom
//
//  Created by Assistant on 2025-06-28.
//

import SwiftUI

struct HabitGridYearModel: Hashable, Sendable {
    let years: [Year]
    
    init(years: [Year]) {
        self.years = years
    }
    
    init() {
        var years = [Year]()
        for index in 0 ..< 5 {
            years.insert(Year(id: index, isComplete: nil), at: 0)
        }
        self.years = years
    }
}

extension HabitGridYearModel {
    struct Year: Identifiable, Hashable, Sendable {
        let id: Int
        let isComplete: Bool?
        let isCurrentYear: Bool
        let referenceDate: Date
        let yearLabel: String
        
        init(
            id: Int,
            isComplete: Bool?,
            isCurrentYear: Bool = false,
            referenceDate: Date = .now,
            yearLabel: String = ""
        ) {
            self.id = id
            self.isComplete = isComplete
            self.isCurrentYear = isCurrentYear
            self.referenceDate = referenceDate
            self.yearLabel = yearLabel
        }
    }
}