//
//  NutritionMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-03.
//

import SwiftUI
import HealthKit
import DataContainer

extension Double {
    static let caloriesPerGramOfProtein: Double = 4
    static let caloriesPerGramOfCarbs: Double = 4
    static let caloriesPerGramOfFat: Double = 9
    static let netEnergySignificantThreshold: Double = 500
}

extension NutritionMonthlySummary {

    struct Status {
        let title: String
        let color: Color
    }
}

struct NutritionMonthlySummary: Hashable, Sendable {
    let details: Details
}

extension NutritionMonthlySummary {

    var subtitle: String? {
        let macros = details.macroStatus.map { "Macros \($0.rawValue)" }
        let water = details.waterStatus
//        let vitamins = details.vitaminStatus
//        let minerals = details.mineralStatus

        let entries = [
            details.netEnergyDisplayString,
            macros,
            water
        ].compactMap({ $0 })

        guard entries.isNotEmpty else { return nil }

        return entries.joined(separator: "\n")
    }

    var score: Double {
        details.score ?? 1
    }

    var hasNoData: Bool {
        details.score == nil
    }

    var barLevel: VitalModel.BarLevel? {
        guard let score = details.score else { return nil }

        if score < 0.4 {
            return VitalModel.BarLevel(
                level: .low,
                proportion: score.scaledPercent(lower: 0, upper: 0.4)
            )
        } else if score < 0.7 {
            return VitalModel.BarLevel(
                level: .medium,
                proportion: score.scaledPercent(lower: 0.4, upper: 0.7)
            )
        } else if score < 0.9 {
            return VitalModel.BarLevel(
                level: .high,
                proportion: score.scaledPercent(lower: 0.7, upper: 0.9)
            )
        } else {
            return VitalModel.BarLevel(
                level: .optimal,
                proportion: score.scaledPercent(lower: 0.9, upper: 1)
            )
        }
    }

    var status: Status? {
        guard let score = details.score else {
            return nil
        }

        if score < 0.4 {
            return Status(title: "Unhealthy", color: .vitalSevere)
        } else if score < 0.7 {
            return Status(title: "Unbalanced", color: .vitalWarning)
        } else if score < 0.9 {
            return Status(title: "Good", color: .vitalGood)
        }
        return Status(title: "Healthy", color: .vitalGreat)
    }
}

extension NutritionMonthlySummary {
    struct Details: Hashable, Sendable {
        let numberOfNutritionLogDays: Int
        let numberOfProteinLogDays: Int
        let basalEnergyBurned: HKQuantity?
        let activeEnergyBurned: HKQuantity?
        let dietaryEnergy: HKQuantity?
        let averageProtein: HKQuantity?
        let averageCarbohydrates: HKQuantity?
        let averageFat: HKQuantity?
        let averageFiber: HKQuantity?
        let averageSugar: HKQuantity?
        let averageWater: HKQuantity?
    }

    enum NetEnergyStatus {
        case deficit(HKQuantity)
        case surplus(HKQuantity)
    }

    enum MacroStatus: String {
        case proteinSurplus = "Protein Surplus"
        case proteinDeficiency = "Protein Deficiency"
        case carbSurplus = "Carb Surplus"
        case carbDeficiency = "Carb Deficiency"
        case fatSurplus = "Fat Surplus"
        case fatDeficiency = "Fat Deficiency"
        case balanced = "Balanced"
    }

    struct Macros {
        let protein: HKQuantity
        let carbohydrates: HKQuantity
        let fat: HKQuantity
        let remainderCalories: Double

        var total: Double {
            proteinCalories + carbsCalories + fatCalories + remainderCalories
        }

        var proteinCalories: Double {
            protein.doubleValue(for: .gram()) * .caloriesPerGramOfProtein
        }

        var proteinPercent: Double {
            protein.doubleValue(for: .gram()) * .caloriesPerGramOfProtein / total
        }

        var carbsCalories: Double {
            carbohydrates.doubleValue(for: .gram()) * .caloriesPerGramOfCarbs
        }

        var carbsPercent: Double {
            carbsCalories / total
        }

        var fatCalories: Double {
            fat.doubleValue(for: .gram()) * .caloriesPerGramOfFat
        }

        var fatPercent: Double {
            fatCalories / total
        }
    }

    enum NutrientCategory {
        case deficiency
        case surplus
        case recommended
    }
}

extension NutritionMonthlySummary.Details {

    var hasSufficientNutritionLogs: Bool {
        numberOfNutritionLogDays >= 7
    }

    var hasSufficientProteinLogs: Bool {
        numberOfProteinLogDays >= 7
    }

    var netEnergy: Double? {
        guard let basalEnergyBurned, let activeEnergyBurned, let dietaryEnergy else { return nil }

        return dietaryEnergy.doubleValue(for: .largeCalorie()) 
            - basalEnergyBurned.doubleValue(for: .largeCalorie())
            - activeEnergyBurned.doubleValue(for: .largeCalorie())
    }

    var netEnergyDisplayString: String? {
        guard let netEnergy else { return nil }

        if netEnergy < -.netEnergySignificantThreshold {
            return "Energy Deficit"
        } else if netEnergy < 0 {
            return "Slight Energy Deficiency"
        } else if netEnergy > .netEnergySignificantThreshold {
            return "Energy Surplus"
        }
        return "Slight Energy Surplus"
    }

    var netEnergyDescription: String? {
        guard let netEnergy else { return nil }

        if netEnergy < -.netEnergySignificantThreshold {
            return "A large caloric deficit can lead to rapid weight loss, and can have negative health effects such as nutrient deficiencies, muscle loss, gallstones, or fatigue."
        } else if netEnergy < 0 {
            return "A caloric deficit can help with sustainable weight loss while maintaining muscle mass."
        } else if netEnergy > .netEnergySignificantThreshold {
            return "A large caloric surplus can lead to rapid weight gain, and can incrase the risk of various health issues such as cardiovascular diseases or type 2 diabetes."
        }
        return "A caloric surplus can help promote muscle growth and provide you with more energy."
    }

    var netEnergyStatus: NutritionMonthlySummary.NetEnergyStatus? {
        guard let basalEnergyBurned, let activeEnergyBurned, let dietaryEnergy else { return nil }

        let tdee = basalEnergyBurned.doubleValue(for: .largeCalorie()) + activeEnergyBurned.doubleValue(for: .largeCalorie())
        let dietary = dietaryEnergy.doubleValue(for: .largeCalorie())

        if dietary > tdee {
            let percent = (dietary / tdee) - 1

            return .surplus(HKQuantity(unit: .percent(), doubleValue: percent * 100))
        }

        let percent = 1 - (dietary / tdee)

        return .deficit(HKQuantity(unit: .percent(), doubleValue: percent * 100))
    }

    var score: Double? {
        let allNutrients = [
            netEnergyScore,
            macrosScore,
            otherScore
        ].unwrap()

        if allNutrients.isEmpty {
            return nil
        }
        return allNutrients.average(keyPath: \.self)
    }

    var netEnergyScore: Double? {
        guard let netEnergy else { return nil }

        return netEnergy.invertedScaledPercent(lower: -.netEnergySignificantThreshold, upper: .netEnergySignificantThreshold)
    }

    var macros: NutritionMonthlySummary.Macros? {
        guard let averageProtein, let averageCarbohydrates, let averageFat, let dietaryEnergy else { return nil }

        let protein = averageProtein.doubleValue(for: .gram()) * .caloriesPerGramOfProtein
        let carbs = averageCarbohydrates.doubleValue(for: .gram()) * .caloriesPerGramOfCarbs
        let fat = averageFat.doubleValue(for: .gram()) * .caloriesPerGramOfFat
        let remainder = dietaryEnergy.doubleValue(for: .largeCalorie()) - protein - carbs - fat

        return .init(
            protein: averageProtein,
            carbohydrates: averageCarbohydrates,
            fat: averageFat,
            remainderCalories: remainder
        )
    }

    var macrosScore: Double? {
        let macros = [
            proteinScore,
            carbohydratesScore,
            fatScore
        ].compactMap({ $0 })

        if macros.isEmpty {
            return nil
        }
        return macros.average(keyPath: \.self)
    }

    var macroStatus: NutritionMonthlySummary.MacroStatus? {
        if macrosScore == nil {
            return nil
        }
        if fatScore ?? 1 < carbohydratesScore ?? 0 && fatScore ?? 1 < proteinScore ?? 0, let fatCategory {
            switch fatCategory {
            case .deficiency:
                return .fatDeficiency
            case .surplus:
                return .fatSurplus
            case .recommended:
                break
            }
        }
        if proteinScore ?? 1 < carbohydratesScore ?? 0 && proteinScore ?? 1 < fatScore ?? 0, let proteinCategory {
            switch proteinCategory {
            case .deficiency:
                return .proteinDeficiency
            case .surplus:
                return .proteinSurplus
            case .recommended:
                break
            }
        }
        if carbohydratesScore ?? 1 < proteinScore ?? 0 && carbohydratesScore ?? 1 < fatScore ?? 0, let carbohydratesCategory {
            switch carbohydratesCategory {
            case .deficiency:
                return .carbDeficiency
            case .surplus:
                return .carbSurplus
            case .recommended:
                break
            }

        }
        return .balanced
    }

    var proteinCategory: NutritionMonthlySummary.NutrientCategory? {
        guard let average = averageProtein, let dietaryEnergy else { return nil }

        let goal = HealthGoalProvider.shared.recommendedDailyProteinPercentOfDietaryEnergy()

        let calories = average.doubleValue(for: .gram()) * .caloriesPerGramOfProtein
        let percent = calories / dietaryEnergy.doubleValue(for: .largeCalorie())

        if percent < goal.lowerBound {
            return .deficiency
        } else if percent > goal.upperBound {
            return .surplus
        } else {
            return .recommended
        }
    }

    var proteinScore: Double? {
        guard let average = averageProtein, let dietaryEnergy, average.doubleValue(for: .gram()) >= 1 else { return nil }

        let goal = HealthGoalProvider.shared.recommendedDailyProteinPercentOfDietaryEnergy()

        let calories = average.doubleValue(for: .gram()) * .caloriesPerGramOfProtein
        let percent = calories / dietaryEnergy.doubleValue(for: .largeCalorie())

        return percent.invertedScaledPercent(lower: goal.lowerBound, upper: goal.upperBound)
    }

    var carbohydratesCategory: NutritionMonthlySummary.NutrientCategory? {
        guard let average = averageCarbohydrates, let dietaryEnergy else { return nil }

        let goal = HealthGoalProvider.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy()

        let calories = average.doubleValue(for: .gram()) * .caloriesPerGramOfCarbs
        let percent = calories / dietaryEnergy.doubleValue(for: .largeCalorie())

        if percent < goal.lowerBound {
            return .deficiency
        } else if percent > goal.upperBound {
            return .surplus
        } else {
            return .recommended
        }
    }

    var carbohydratesScore: Double? {
        guard let average = averageCarbohydrates, let dietaryEnergy, average.doubleValue(for: .gram()) >= 1 else { return nil }

        let goal = HealthGoalProvider.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy()

        let calories = average.doubleValue(for: .gram()) * .caloriesPerGramOfCarbs
        let percent = calories / dietaryEnergy.doubleValue(for: .largeCalorie())

        return percent.invertedScaledPercent(lower: goal.lowerBound, upper: goal.upperBound)
    }

    var fatCategory: NutritionMonthlySummary.NutrientCategory? {
        guard let average = averageFat, let dietaryEnergy else { return nil }

        let goal = HealthGoalProvider.shared.recommendedDailyFatPercentOfDietaryEnergy()

        let calories = average.doubleValue(for: .gram()) * .caloriesPerGramOfFat
        let percent = calories / dietaryEnergy.doubleValue(for: .largeCalorie())

        if percent < goal.lowerBound {
            return .deficiency
        } else if percent > goal.upperBound {
            return .surplus
        } else {
            return .recommended
        }
    }

    var fatScore: Double? {
        guard let average = averageFat, let dietaryEnergy, average.doubleValue(for: .gram()) >= 1 else { return nil }

        let goal = HealthGoalProvider.shared.recommendedDailyFatPercentOfDietaryEnergy()

        let calories = average.doubleValue(for: .gram()) * .caloriesPerGramOfFat
        let percent = calories / dietaryEnergy.doubleValue(for: .largeCalorie())

        return percent.invertedScaledPercent(lower: goal.lowerBound, upper: goal.upperBound)
    }

    var otherScore: Double? {
        let other = [
            fiberScore,
            sugarScore,
            waterScore
        ].compactMap({ $0 })

        if other.isEmpty {
            return nil
        }
        return other.average(keyPath: \.self)
    }

    var fiberScore: Double? {
        guard
            let average = averageFiber?.doubleValue(for: .gram()),
            average > 0,
            let goal = HealthGoalProvider.shared.recommendedMinDailyIntakeForFiber()?.doubleValue(for: .gram())
        else { return nil }

        return average.scaledPercent(lower: 0, upper: goal)
    }

    var sugarScore: Double? {
        guard 
            let average = averageSugar?.doubleValue(for: .gram()),
            average > 0,
            let goal = HealthGoalProvider.shared.recommendedMaxDailyIntakeForSugar()?.doubleValue(for: .gram())
        else { return nil }

        return average.scaledPercent(lower: goal * 2, upper: goal)
    }

//    var caffeineScore: Double? {
//        guard
//            let average = averageCaffeine?.doubleValue(for: .gramUnit(with: .milli)),
//            let goal = HealthManager.shared.recommendedMaxDailyCaffeine()?.doubleValue(for: .gramUnit(with: .milli))
//        else { return nil }
//
//        return average.scaledPercent(lower: goal * 2, upper: goal)
//    }

    var waterStatus: String? {
        guard
            let average = averageWater?.doubleValue(for: .literUnit(with: .milli)),
            average > 0
        else { return nil }

        if average < 1000 {
            return "Dehydrated"
        } else if average < 2000 {
            return "Slightly Dehydrated"
        }
        return "Hydrated"
    }

    var waterScore: Double? {
        guard
            let average = averageWater?.doubleValue(for: .literUnit(with: .milli)),
            average > 0
        else { return nil }

        return average.scaledPercent(lower: 0, upper: 2000) // TODO: Make this more official
    }

//    var vitaminScore: Double? {
//        let vitamins = [
//            vitaminAScore,
//            vitaminB6Score,
//            vitaminB12Score,
//            vitaminCScore,
//            vitaminDScore,
//            vitaminEScore
//        ].compactMap({ $0 })
//
//        if vitamins.isEmpty {
//            return nil
//        }
//
//        return vitamins.average(keyPath: \.self)
//    }

//    var vitaminStatus: String? {
//        let pairs = [
//            ("Vitamin A", vitaminAScore),
//            ("Vitamin B6", vitaminB6Score),
//            ("Vitamin B12", vitaminB12Score),
//            ("Vitamin C", vitaminCScore),
//            ("Vitamin D", vitaminDScore),
//            ("Vitamin E", vitaminEScore)
//        ].compactMap({
//            if let value = $0.1 {
//                return ($0.0, value)
//            }
//            return nil
//        })
//
//        guard let lowestPair = pairs.min(by: { $0.1 < $1.1 }) else { return nil }
//
//        if lowestPair.1 > 0.99 {
//            return "Vitamins Balanced"
//        } else if pairs.filter({ $0.1 < 0.99 }).count > 1 {
//            return "Vitamin Imbalance"
//        }
//
//        return "\(lowestPair.0) Imbalance"
//    }
//
//    var vitaminAScore: Double? {
//        let unit = HKUnit.gramUnit(with: .micro)
//        guard
//            let average = averageVitaminA?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedDailyIntakeForVitaminA()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
//
//    var vitaminB6Score: Double? {
//        let unit = HKUnit.gramUnit(with: .milli)
//        guard
//            let average = averageVitaminB6?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedDailyIntakeForVitaminB6()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
//
//    var vitaminB12Score: Double? {
//        let unit = HKUnit.gramUnit(with: .micro)
//        guard
//            let average = averageVitaminB12?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedMinDailyIntakeForVitaminB12()
//        else { return nil }
//
//        return average.scaledPercent(
//            lower: 0,
//            upper: goal.doubleValue(for: unit)
//        )
//    }
//
//    var vitaminCScore: Double? {
//        let unit = HKUnit.gramUnit(with: .milli)
//        guard
//            let average = averageVitaminC?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedDailyIntakeForVitaminC()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
//
//    var vitaminDScore: Double? {
//        let unit = HKUnit.gramUnit(with: .micro)
//        guard
//            let average = averageVitaminD?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedDailyIntakeForVitaminD()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
//
//    var vitaminEScore: Double? {
//        let unit = HKUnit.gramUnit(with: .milli)
//        guard
//            let average = averageVitaminE?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedDailyIntakeForVitaminE()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
//
//    var mineralScore: Double? {
//        let minerals = [
//            calciumScore,
//            ironScore,
//            magnesiumScore,
//            potassiumScore,
//            sodiumScore,
//            zincScore
//        ].compactMap({ $0 })
//
//        if minerals.isEmpty {
//            return nil
//        }
//
//        return minerals.average(keyPath: \.self)
//    }
//
//    var mineralStatus: String? {
//        let pairs = [
//            ("Calcium", calciumScore),
//            ("Iron", ironScore),
//            ("Magnesium", magnesiumScore),
//            ("Potassium", potassiumScore),
//            ("Sodium", sodiumScore),
//            ("Zinc", zincScore)
//        ].compactMap({
//            if let value = $0.1 {
//                return ($0.0, value)
//            }
//            return nil
//        })
//
//        guard let lowestPair = pairs.min(by: { $0.1 < $1.1 }) else { return nil }
//
//        if lowestPair.1 > 0.99 {
//            return "Minerals Balanced"
//        } else if pairs.filter({ $0.1 < 0.99 }).count > 1 {
//            return "Mineral Imbalance"
//        }
//
//        return "\(lowestPair.0) Imbalance"
//    }
//
//    var calciumScore: Double? {
//        let unit = HKUnit.gramUnit(with: .milli)
//
//        guard
//            let average = averageCalcium?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedIntakeForCalcium()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
//
//    var ironScore: Double? {
//        let unit = HKUnit.gramUnit(with: .milli)
//
//        guard
//            let average = averageIron?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedDailyIntakeForIron()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
//
//    var magnesiumScore: Double? {
//        let unit = HKUnit.gramUnit(with: .milli)
//
//        guard
//            let average = averageMagnesium?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedDailyIntakeForMagnesium()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
//
//    var potassiumScore: Double? {
//        let unit = HKUnit.gramUnit(with: .milli)
//
//        guard
//            let average = averagePotassium?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedDailyIntakeForPotassium()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
//
//    var sodiumScore: Double? {
//        let unit = HKUnit.gramUnit(with: .milli)
//
//        guard
//            let average = averageSodium?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedDailyIntakeForSodium()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
//
//    var zincScore: Double? {
//        let unit = HKUnit.gramUnit(with: .milli)
//
//        guard
//            let average = averageZinc?.doubleValue(for: unit),
//            let goal = HealthManager.shared.recommendedDailyIntakeForZinc()
//        else { return nil }
//
//        return average.invertedScaledPercent(
//            lower: goal.lowerDoubleValue(for: unit),
//            upper: goal.upperDoubleValue(for: unit)
//        )
//    }
}
