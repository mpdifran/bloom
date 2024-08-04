//
//  NutritionMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-03.
//

import SwiftUI
import HealthKit

private extension Double {
    static let caloriesPerGramOfProtein: Double = 4
    static let caloriesPerGramOfCarbs: Double = 4
    static let caloriesPerGramOfFat: Double = 9
}

extension NutritionMonthlySummary {

    struct Status {
        let title: String
        let color: Color
    }
}

struct NutritionMonthlySummary: Hashable {
    let bodyWeight: HKQuantitySample?
    let details: Details
    let lastMonthDetails: Details
}

extension NutritionMonthlySummary {

    var subtitle: String {
        let macros = "Macros: \(details.macroStatus.rawValue)"
        let sugar = details.averageSugar.map { "Sugar: \($0.displayString(for: .gram()))" }
        let vitamins = details.vitaminStatus

        return [
            macros,
            sugar,
            vitamins
        ].compactMap({ $0 })
            .joined(separator: "\n")
    }

    var score: Double {
        details.score ?? 1
    }

    var trend: VitalModel.Trend {
        if let thisMonth = details.score, let lastMonth = details.score {
            return thisMonth < lastMonth ? .decreasing : .increasing
        }
        return .noTrend
    }

    var status: Status {
        guard let score = details.score else {
            return Status(title: "No Data", color: .gray)
        }

        if score < 0.4 {
            return Status(title: "Unhealthy", color: .pink)
        } else if score < 0.8 {
            return Status(title: "Unbalanced", color: .yellow)
        } else if score < 1 {
            return Status(title: "Good", color: .green)
        }
        return Status(title: "Healthy", color: .coreSleep)
    }
}

extension NutritionMonthlySummary {
    struct Details: Hashable {
        let dietaryEnergy: HKQuantity?
        let averageProtein: HKQuantity?
        let averageCarbohydrates: HKQuantity?
        let averageFat: HKQuantity?
        let averageSugar: HKQuantity?
        let averageVitaminA: HKQuantity?
        let averageVitaminB6: HKQuantity?
        let averageVitaminB12: HKQuantity?
        let averageVitaminC: HKQuantity?
        let averageVitaminD: HKQuantity?
        let averageVitaminE: HKQuantity?
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

    enum NutrientCategory {
        case deficiency
        case surplus
        case recommended
    }
}

extension NutritionMonthlySummary.Details {

    var score: Double? {
        let allNutrients = [
            macrosScore,
            sugarScore,
            vitaminScore
        ].compactMap({ $0 })

        if allNutrients.isEmpty {
            return nil
        }
        return allNutrients.average(keyPath: \.self)
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

    var macroStatus: NutritionMonthlySummary.MacroStatus {
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

        let goal = HealthManager.shared.recommendedDailyProteinPercentOfDietaryEnergy()

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
        guard let average = averageProtein, let dietaryEnergy else { return nil }

        let goal = HealthManager.shared.recommendedDailyProteinPercentOfDietaryEnergy()

        let calories = average.doubleValue(for: .gram()) * .caloriesPerGramOfProtein
        let percent = calories / dietaryEnergy.doubleValue(for: .largeCalorie())

        return percent.invertedScaledPercent(lower: goal.lowerBound, upper: goal.upperBound)
    }

    var carbohydratesCategory: NutritionMonthlySummary.NutrientCategory? {
        guard let average = averageCarbohydrates, let dietaryEnergy else { return nil }

        let goal = HealthManager.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy()

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
        guard let average = averageCarbohydrates, let dietaryEnergy else { return nil }

        let goal = HealthManager.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy()

        let calories = average.doubleValue(for: .gram()) * .caloriesPerGramOfCarbs
        let percent = calories / dietaryEnergy.doubleValue(for: .largeCalorie())

        return percent.invertedScaledPercent(lower: goal.lowerBound, upper: goal.upperBound)
    }

    var fatCategory: NutritionMonthlySummary.NutrientCategory? {
        guard let average = averageFat, let dietaryEnergy else { return nil }

        let goal = HealthManager.shared.recommendedDailyFatPercentOfDietaryEnergy()

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
        guard let average = averageFat, let dietaryEnergy else { return nil }

        let goal = HealthManager.shared.recommendedDailyFatPercentOfDietaryEnergy()

        let calories = average.doubleValue(for: .gram()) * .caloriesPerGramOfFat
        let percent = calories / dietaryEnergy.doubleValue(for: .largeCalorie())

        return percent.invertedScaledPercent(lower: goal.lowerBound, upper: goal.upperBound)
    }

    var sugarScore: Double? {
        guard 
            let average = averageSugar?.doubleValue(for: .gram()),
            let goal = HealthManager.shared.recommendedMaxDailyIntakeForSugar()?.doubleValue(for: .gram())
        else { return nil }

        return average.scaledPercent(lower: goal * 2, upper: goal)
    }

    var vitaminScore: Double? {
        let vitamins = [
            vitaminAScore,
            vitaminB6Score,
            vitaminB12Score,
            vitaminCScore,
            vitaminDScore,
            vitaminEScore
        ].compactMap({ $0 })

        if vitamins.isEmpty {
            return nil
        }

        return vitamins.average(keyPath: \.self)
    }

    var vitaminStatus: String? {
        let pairs = [
            ("Vitamin A", vitaminAScore),
            ("Vitamin B6", vitaminB6Score),
            ("Vitamin B12", vitaminB12Score),
            ("Vitamin C", vitaminCScore),
            ("Vitamin D", vitaminDScore),
            ("Vitamin E", vitaminEScore)
        ].compactMap({
            if let value = $0.1 {
                return ($0.0, value)
            }
            return nil
        })

        guard let lowestPair = pairs.min(by: { $0.1 < $1.1 }) else { return nil }

        if lowestPair.1 > 0.99 {
            return "Vitamins Balanced"
        }
        return "\(lowestPair.0) Imbalance"
    }

    var vitaminAScore: Double? {
        let unit = HKUnit.gramUnit(with: .micro)
        guard
            let average = averageVitaminA?.doubleValue(for: unit),
            let goal = HealthManager.shared.recommendedDailyIntakeForVitaminA()
        else { return nil }

        return average.invertedScaledPercent(
            lower: goal.lowerDoubleValue(for: unit),
            upper: goal.upperDoubleValue(for: unit)
        )
    }

    var vitaminB6Score: Double? {
        let unit = HKUnit.gramUnit(with: .milli)
        guard
            let average = averageVitaminB6?.doubleValue(for: unit),
            let goal = HealthManager.shared.recommendedDailyIntakeForVitaminB6()
        else { return nil }

        return average.invertedScaledPercent(
            lower: goal.lowerDoubleValue(for: unit),
            upper: goal.upperDoubleValue(for: unit)
        )
    }

    var vitaminB12Score: Double? {
        let unit = HKUnit.gramUnit(with: .micro)
        guard
            let average = averageVitaminB12?.doubleValue(for: unit),
            let goal = HealthManager.shared.recommendedMinDailyIntakeForVitaminB12()
        else { return nil }

        return average.scaledPercent(
            lower: 0,
            upper: goal.doubleValue(for: unit)
        )
    }

    var vitaminCScore: Double? {
        let unit = HKUnit.gramUnit(with: .milli)
        guard
            let average = averageVitaminC?.doubleValue(for: unit),
            let goal = HealthManager.shared.recommendedDailyIntakeForVitaminC()
        else { return nil }

        return average.invertedScaledPercent(
            lower: goal.lowerDoubleValue(for: unit),
            upper: goal.upperDoubleValue(for: unit)
        )
    }

    var vitaminDScore: Double? {
        let unit = HKUnit.gramUnit(with: .micro)
        guard
            let average = averageVitaminD?.doubleValue(for: unit),
            let goal = HealthManager.shared.recommendedDailyIntakeForVitaminD()
        else { return nil }

        return average.invertedScaledPercent(
            lower: goal.lowerDoubleValue(for: unit),
            upper: goal.upperDoubleValue(for: unit)
        )
    }

    var vitaminEScore: Double? {
        let unit = HKUnit.gramUnit(with: .milli)
        guard
            let average = averageVitaminE?.doubleValue(for: unit),
            let goal = HealthManager.shared.recommendedDailyIntakeForVitaminE()
        else { return nil }

        return average.invertedScaledPercent(
            lower: goal.lowerDoubleValue(for: unit),
            upper: goal.upperDoubleValue(for: unit)
        )
    }
}
