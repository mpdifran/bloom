//
//  HabitGridModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-11.
//

import SwiftUI

struct HabitGridModel: Hashable, Sendable {
    let weeks: [Week]

    init(weeks: [Week]) {
        self.weeks = weeks
    }

    init() {
        var weeks = [Week]()
        for index in 0 ..< 40 {
            weeks.insert(Week(id: index, isComplete: []), at: 0)
        }
        self.weeks = weeks
    }
}

extension HabitGridModel {
    struct Week: Identifiable, Hashable, Sendable {
        let id: Int
        let isComplete: [Bool]
        let todayIndex: Int?

        init(
            id: Int,
            isComplete: [Bool],
            todayIndex: Int? = nil
        ) {
            self.id = id
            self.isComplete = isComplete
            self.todayIndex = todayIndex
        }
    }
}
