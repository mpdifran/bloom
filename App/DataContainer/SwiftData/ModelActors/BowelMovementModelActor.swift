//
//  BowelMovementModelActor.swift
//  DataContainer
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation
import SwiftData
import BloomFoundation

public extension BowelMovementModelActor {

    static func standard() -> Self {
        .init(modelContainer: ContainerHolder.shared.container)
    }
}

@ModelActor
public final actor BowelMovementModelActor: Sendable {

    private var context: ModelContext { modelExecutor.modelContext }
}

public extension BowelMovementModelActor {

    func fetchBowelMovements(dateRange: DateRange) throws -> [BowelMovementDTO] {
        let start = dateRange.start
        let end = dateRange.end
        let descriptor = FetchDescriptor<BowelMovement>(
            predicate: #Predicate<BowelMovement> { model in
                model.date >= start && model.date <= end
            },
            sortBy: [SortDescriptor(\BowelMovement.date)]
        )
        let result = try context.fetch(descriptor)

        return result.map { $0.asDTO() }
    }
}
