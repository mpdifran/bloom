//
//  DataFetcher+MonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-17.
//

import Foundation
import DataContainer
import SwiftData

extension ModelContext {

    func fetchBowelMovementMonthlySummary() -> BowelMovementMonthlySummary {
        let samples = (try? fetchBowelMovements(dateRange: .trailingMonthsFromNow(1))) ?? []

        return BowelMovementMonthlySummary(bowelMovements: samples.map({ $0.asDTO() }))
    }
}
