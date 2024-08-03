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
        let protein = details.averageProtein.map { "Protein: \(String(format: "%.0f", $0.doubleValue(for: .gram()))) g" }
        let carbs = details.averageCarbohydrates.map { "Carbs: \(String(format: "%.0f", $0.doubleValue(for: .gram()))) g" }
        let fat = details.averageFat.map { "Fat: \(String(format: "%.0f", $0.doubleValue(for: .gram()))) g" }

        let allValues = [
            protein,
            carbs,
            fat
        ].compactMap({ $0 })

        guard allValues.isNotEmpty else { return "No Data" }

        return allValues.joined(separator: "\n")
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
        guard let _ = details.score else {
            return Status(title: "No Data", color: .gray)
        }

        if details.proteinScore ?? 1 < details.carbohydratesScore ?? 0 && details.proteinScore ?? 1 < details.fatScore ?? 0, let proteinCategory = details.proteinCategory {
            switch proteinCategory {
            case .deficiency:
                return Status(title: "Protein Deficiency", color: .pink)
            case .surplus:
                return Status(title: "Protein Surplus", color: .pink)
            case .recommended:
                break
            }
        }
        if details.carbohydratesScore ?? 1 < details.proteinScore ?? 0 && details.carbohydratesScore ?? 1 < details.fatScore ?? 0, let carbCategory = details.carbohydratesCategory {
            switch carbCategory {
            case .deficiency:
                return Status(title: "Carb Deficiency", color: .pink)
            case .surplus:
                return Status(title: "Carb Surplus", color: .pink)
            case .recommended:
                break
            }

        }
        if details.fatScore ?? 1 < details.carbohydratesScore ?? 0 && details.fatScore ?? 1 < details.proteinScore ?? 0, let fatCategory = details.fatCategory {
            switch fatCategory {
            case .deficiency:
                return Status(title: "Fat Deficiency", color: .pink)
            case .surplus:
                return Status(title: "Fat Surplus", color: .pink)
            case .recommended:
                break
            }
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
    }

    enum NutrientCategory {
        case deficiency
        case surplus
        case recommended
    }
}

extension NutritionMonthlySummary.Details {

    var score: Double? {
        let inputs = [
            proteinScore,
            carbohydratesScore,
            fatScore
        ].compactMap({ $0 })

        if inputs.isEmpty {
            return nil
        }
        return inputs.average(keyPath: \.self)
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
}
