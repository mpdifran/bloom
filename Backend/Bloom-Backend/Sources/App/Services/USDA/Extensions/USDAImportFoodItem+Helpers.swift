//
//  USDAImportFoodItem+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Foundation
import Vapor

extension USDAImportFoodItem {

    func asFoodItemRecord(request: Request, category: FoodItemRecord.Category) async throws -> FoodItemRecord? {
        guard description.isNotEmpty else { return nil }

        let id = "\(fdcId)"
        let foodItemRecord = try await FoodItemRecord.findOrCreate(id: id, on: request.db)

        foodItemRecord.name = description
        foodItemRecord.state = .verified
        foodItemRecord.country = "usa"
        foodItemRecord.category = category
        foodItemRecord.source = "USDA"
        foodItemRecord.brandName = nil
        foodItemRecord.flavour = nil

        let logger = request.logger
        let fdc = "\(fdcId)"

        foodItemRecord.calories          = nutrient(id: 1008, expected: ["KCAL"], fdc: fdc, logger: logger)
        foodItemRecord.protein           = nutrient(id: 1003, expected: ["G"], fdc: fdc, logger: logger)
        foodItemRecord.carbohydrates     = nutrient(id: 1005, expected: ["G"], fdc: fdc, logger: logger)
        foodItemRecord.fiber             = nutrient(id: 1079, expected: ["G"], fdc: fdc, logger: logger)
        foodItemRecord.sugar             = nutrient(id: 2000, expected: ["G"], fdc: fdc, logger: logger)
        foodItemRecord.fat               = nutrient(id: 1004, expected: ["G"], fdc: fdc, logger: logger)
        foodItemRecord.saturatedFat      = nutrient(id: 1258, expected: ["G"], fdc: fdc, logger: logger)
        foodItemRecord.transFat          = nutrient(id: 1257, expected: ["G"], fdc: fdc, logger: logger)
        foodItemRecord.monounsaturatedFat = nutrient(id: 1292, expected: ["G"], fdc: fdc, logger: logger)
        foodItemRecord.polyunsaturatedFat = nutrient(id: 1293, expected: ["G"], fdc: fdc, logger: logger)
        foodItemRecord.cholesterol       = nutrient(id: 1253, expected: ["MG"], fdc: fdc, logger: logger)
        foodItemRecord.sodium            = nutrient(id: 1093, expected: ["MG"], fdc: fdc, logger: logger)
        foodItemRecord.calcium           = nutrient(id: 1087, expected: ["MG"], fdc: fdc, logger: logger)
        foodItemRecord.iron              = nutrient(id: 1089, expected: ["MG"], fdc: fdc, logger: logger)
        foodItemRecord.potassium         = nutrient(id: 1092, expected: ["MG"], fdc: fdc, logger: logger)
        foodItemRecord.magnesium         = nutrient(id: 1090, expected: ["MG"], fdc: fdc, logger: logger)
        foodItemRecord.zinc              = nutrient(id: 1095, expected: ["MG"], fdc: fdc, logger: logger)
        foodItemRecord.vitaminA          = nutrient(id: 1106, expected: ["UG", "MCG"], fdc: fdc, logger: logger)
        foodItemRecord.vitaminB6         = nutrient(id: 1175, expected: ["MG"], fdc: fdc, logger: logger)
        foodItemRecord.vitaminB12        = nutrient(id: 1178, expected: ["UG", "MCG"], fdc: fdc, logger: logger)
        foodItemRecord.vitaminC          = nutrient(id: 1162, expected: ["MG"], fdc: fdc, logger: logger)
        foodItemRecord.vitaminD          = nutrient(id: 1114, expected: ["UG", "MCG"], fdc: fdc, logger: logger)
        foodItemRecord.vitaminE          = nutrient(id: 1109, expected: ["MG"], fdc: fdc, logger: logger)

        if let portion = foodPortions.first {
            var servingName = "\(portion.amount.prettyFormat()) \(portion.measureUnit.name)"
            if let modifier = portion.modifier, modifier.isNotEmpty {
                servingName += " (\(modifier))"
            }
            foodItemRecord.servingName = servingName
            foodItemRecord.servingValue = portion.gramWeight
            foodItemRecord.servingUnit = "g"
        } else {
            foodItemRecord.servingName = "100 g"
            foodItemRecord.servingValue = 100
            foodItemRecord.servingUnit = "g"
        }

        return foodItemRecord
    }

    /// Looks up a nutrient by FDC id and validates the unit matches one of `expected`
    /// (case-insensitive). Returns the amount or nil if missing/unit mismatch.
    private func nutrient(
        id: Int,
        expected: [String],
        fdc: String,
        logger: Logger
    ) -> Double? {
        guard let entry = foodNutrients.first(where: { $0.nutrient.id == id }) else { return nil }
        guard let amount = entry.amount else { return nil }

        let unit = entry.nutrient.unitName.uppercased()
        let allowed = Set(expected.map { $0.uppercased() })
        guard allowed.contains(unit) else {
            logger.warning("USDA fdcId=\(fdc) nutrient=\(id) unit mismatch: got \(unit), expected \(expected.joined(separator: "/"))")
            return nil
        }
        return amount
    }
}
