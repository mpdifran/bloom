//
//  WaterGlassSizeModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-24.
//

import Foundation
import HealthKit

struct WaterGlassSizeModel: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let quantityValue: Double
    let unitString: String

    init(
        id: UUID = UUID(),
        name: String,
        quantityValue: Double,
        unitString: String
    ) {
        self.id = id
        self.name = name
        self.quantityValue = quantityValue
        self.unitString = unitString
    }

    init(
        id: UUID = UUID(),
        name: String,
        quantityValue: Double,
        unit: HKUnit
    ) {
        self.id = id
        self.name = name
        self.quantityValue = quantityValue
        self.unitString = unit.unitString
    }
}

extension WaterGlassSizeModel {

    var unit: HKUnit {
        HKUnit(from: unitString)
    }

    var quantity: HKQuantity {
        HKQuantity(unit: unit, doubleValue: quantityValue)
    }

    var displayValue: String {
        quantity.displayString(for: unit, formatter: NumberFormatter.noDecimalPlaces)
    }
}
