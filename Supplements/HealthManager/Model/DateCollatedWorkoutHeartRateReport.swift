//
//  DateCollatedWorkoutHeartRateReport.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import Foundation

struct DateCollatedWorkoutHeartRateReport: Identifiable, Hashable {
    var id: Int { hashValue }

    let date: Date
    let reports: [WorkoutHeartRateReport]
}
