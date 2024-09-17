//
//  DataFetcher+MonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-17.
//

import Foundation
import DataContainer

extension DataFetcher {

    func fetchBowelMovementMonthlySummary() async -> BowelMovementMonthlySummary {
        let thisMonth = (try? fetchBowelMovements(dateRange: .trailingMonthsFromNow(1))) ?? []
        let lastMonth = (try? fetchBowelMovements(dateRange: .trailingMonthsFromNow(1))) ?? []

        return BowelMovementMonthlySummary(
            details: thisMonth.isNotEmpty ? .init(bowelMovements: thisMonth) : nil,
            lastMonth: lastMonth.isNotEmpty ? .init(bowelMovements: lastMonth) : nil
        )
    }
}
