//
//  Habit+DTO.swift
//  DataContainer
//
//  Created by Mark DiFranco on 2024-10-02.
//

import Foundation

public struct HabitDTO: Sendable {
    public let targetMetric: TargetMetric
    public let value: Double
    public let unitString: String
    public let startDate: Date
    public let endDate: Date?
    public let isSuggested: Bool
    public let isUserEdited: Bool
    public let vitalKind: VitalModel.Kind?
    public let context: String?
}

public extension Habit {

    func asDTO() -> HabitDTO {
        HabitDTO(
            targetMetric: targetMetric,
            value: value,
            unitString: unitString,
            startDate: startDate,
            endDate: endDate,
            isSuggested: isSuggested,
            isUserEdited: isUserEdited,
            vitalKind: vitalKind,
            context: context
        )
    }
}
