//
//  HabitGridWeekModel.swift
//  Bloom
//
//  Created by Assistant on 2025-06-28.
//

import SwiftUI

struct HabitGridWeekModel: Hashable, Sendable {
    let weeks: [Week]
    
    init(weeks: [Week]) {
        self.weeks = weeks
    }
    
    init() {
        var weeks = [Week]()
        for index in 0 ..< 20 {
            weeks.insert(Week(id: index, isComplete: nil), at: 0)
        }
        self.weeks = weeks
    }
}

extension HabitGridWeekModel {
    struct Week: Identifiable, Hashable, Sendable {
        let id: Int
        let isComplete: Bool?
        let isCurrentWeek: Bool
        let referenceDate: Date
        let monthLabel: String?
        
        init(
            id: Int,
            isComplete: Bool?,
            isCurrentWeek: Bool = false,
            referenceDate: Date = .now,
            monthLabel: String? = nil
        ) {
            self.id = id
            self.isComplete = isComplete
            self.isCurrentWeek = isCurrentWeek
            self.referenceDate = referenceDate
            self.monthLabel = monthLabel
        }
    }
}