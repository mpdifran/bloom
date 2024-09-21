//
//  HabitGridModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-11.
//

import SwiftUI

struct HabitGridModel: Sendable {
    let weeks: [Week]

    init(weeks: [Week]) {
        self.weeks = weeks
    }

    init() {
        var weeks = [Week]()
        for index in 0 ..< 40 {
            weeks.append(Week(id: index, isComplete: Array(repeating: false, count: 7)))
        }
        self.weeks = weeks
    }
}

extension HabitGridModel {
    struct Week: Identifiable, Sendable {
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
