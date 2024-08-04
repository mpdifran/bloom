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
        "Macros: \(details.macroStatus.rawValue)"
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

        if score < 0.6 {
            return Status(title: "Unhealthy", color: .pink)
        } else if score < 1 {
            return Status(title: "Unbalanced", color: .yellow)
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
}
