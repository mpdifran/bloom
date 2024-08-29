//
//  DataFetcher.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import Foundation
import SwiftData

final actor DataFetcher {
    static let shared = DataFetcher()

    private let context: ModelContext

    init() {
        context = ModelContext(ContainerHolder.shared.container)
    }
}

private extension DataFetcher {

    func fetch<Model>(
        _ modelType: Model.Type,
        dateRange: DateRange
    ) throws -> [Model] where Model: PersistentModel, Model: IdentifiableByDate {
        let start = dateRange.start
        let end = dateRange.end
        let descriptor = FetchDescriptor<Model>(
            predicate: #Predicate<Model> { model in
                model.date >= start && model.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }

    func fetchBowelMovements(
        dateRange: DateRange
    ) throws -> [BowelMovement] {
        let start = dateRange.start
        let end = dateRange.end
        let descriptor = FetchDescriptor<BowelMovement>(
            predicate: #Predicate<BowelMovement> { model in
                model.date >= start && model.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }
}

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
