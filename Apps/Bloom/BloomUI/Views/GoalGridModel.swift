//
//  GoalGridModel.swift
//  BloomUI
//
//  Created by Mark DiFranco on 2024-09-11.
//

import SwiftUI

public struct GoalGridModel: Hashable, Sendable, Codable {
    public let weeks: [Week]

    public init(weeks: [Week]) {
        self.weeks = weeks
    }

    public init() {
        var weeks = [Week]()
        for index in 0 ..< 40 {
            weeks.insert(Week(id: index, isComplete: []), at: 0)
        }
        self.weeks = weeks
    }
}

public extension GoalGridModel {
    struct Week: Identifiable, Hashable, Sendable, Codable {
        public let id: Int
        public let isComplete: [Bool]
        public let todayIndex: Int?

        public init(
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
