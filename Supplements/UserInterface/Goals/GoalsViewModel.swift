//
//  GoalsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import HealthKit

private extension Int {
    static let numWeeksPastAverage: Int = 3
}

private extension Double {
    static let goalMultiplier: Double = 1.1
}

final actor GoalsViewModel: ObservableObject {
    static let shared = GoalsViewModel()

    @MainActor @Published var goals = [[GoalModel]]() {
        didSet {
            do {
                let data = try JSONEncoder.main.encode(goals)
                UserDefaults.group.set(data, forKey: "GoalsViewModel.goals")
            } catch {
                print(error)
            }
        }
    }

    private init() {
        Task {
            await loadGoals()
        }
    }
}

extension GoalsViewModel {

    func loadGoals() async {
        if
            let data = UserDefaults.group.data(forKey: "GoalsViewModel.goals"),
            let goals = try? JSONDecoder.main.decode([[GoalModel]].self, from: data)
        {
            await MainActor.run {
                self.goals = goals
            }
        }
    }

    func checkForUpdateGoals(force: Bool = false) async {
        await loadGoals()

        if let goalDueDate = await goals.first?.first?.dueDate {
            if goalDueDate > .now && !force {
                print("Returning early since goals are still valid")
                return
            }
        }

        guard let dueDate = Calendar.current.nextMondayMorning(for: .now) else { return }

        var goals = [[GoalModel]]()

        var vitalNames = [String]()
        let sortedVitals = VitalsViewModel.shared.vitals.sorted(by: { $0.score < $1.score })

        if let vital = sortedVitals.safeAccess(at: 0) {
            let goal = await goal(for: vital, dueDate: dueDate)
            if goal.isNotEmpty {
                goals.append(goal)
                vitalNames.append(vital.id.name)
            }
        }

        if let vital = sortedVitals.safeAccess(at: 1) {
            let goal = await goal(for: vital, dueDate: dueDate)
            if goal.isNotEmpty {
                goals.append(goal)
                vitalNames.append(vital.id.name)
            }
        }

        let newGoals = goals

        await MainActor.run {
            self.goals = newGoals
        }

        let listFormatter = ListFormatter()
        let string = listFormatter.string(from: vitalNames)

        let subtitle: String
        if let string {
            subtitle = "Check out your new goals this week targeting \(string)!"
        } else {
            subtitle = "Check out your new goals this week!"
        }

        if !force {
            await NotificationManager.shared.sendNotification(
                title: "New Goals Available",
                subtitle: subtitle,
                categoryID: .CategoryID.goalsMessage
            )
        }
    }
}

private extension GoalsViewModel {

    func goal(for vital: VitalModel, dueDate: Date) async -> [GoalModel] {
        switch vital.id {
        case .sleepQuality:
            let meditation = await meditationGoal(
                summary: "Your sleep quality is low. Meditating before bed can help you wind down.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let timeInDaylight = await timeInDaylightGoal(
                summary: "Your sleep scores have been a bit low lately. Try getting some more sunlight than you normally do this week!",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            return [timeInDaylight, meditation]
        case .activityLevel:
            let steps = await stepGoal(
                summary: "Let's improve your activty level by incorporating more steps in your day. Walking has numerous other health benefits.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let walkRunDistance = await walkRunDistanceGoal(
                summary: "An easy way to improve your activity level is to incorporate more walking and running into your week.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let walkDuration = await walkDurationGoal(
                summary: "An easy way to improve your activity level is to incorporate more walking into your week.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let hikeDuration = await hikeDurationGoal(
                summary: "Hiking is a great way to be more active!",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            return [walkDuration, steps, walkRunDistance, hikeDuration]
        case .cardioFitness:
            let walkRunDistance = await walkRunDistanceGoal(
                summary: "Increasing your walking and running distance this week can help you improve your cardio fitness.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let runDistance = await runDistanceGoal(
                summary: "Running is a great way to improve your cardio fitness.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let stepGoal = await stepGoal(
                summary: "Increasing your step count can have a positive impact on your cardio fitness.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let walkDuration = await walkDurationGoal(
                summary: "Walking for longer can help improve your cardio fitness.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let hiitDuration = await hiitDurationGoal(
                summary: "Doing more high intensity interval training can help improve your cardio fitness.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            return [walkRunDistance, runDistance, stepGoal, walkDuration, hiitDuration]
        case .bodyComposition:
            let steps = await stepGoal(
                summary: "Your body composition is out of the recommended range. A quick way to start making progess is to increase your steps.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let walkRunDistance = await walkRunDistanceGoal(
                summary: "Your body composition is out of the recommended range. Increasing your walking and running distance this week can help you improve.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let walkDuration = await walkDurationGoal(
                summary: "Your body composition is out of the recommended range. A quick way to start making progess is to walk for longer.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            return [steps, walkRunDistance, walkDuration]
        case .stressLevels:
            let meditation = await meditationGoal(
                summary: "Your stress levels are getting quite high. Try incorporating more meditation this week.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            let walkDuration = await walkDurationGoal(
                summary: "Walking is a great way to relive stress. Try spending more time walking this week.",
                vitalKind: vital.id,
                dueDate: dueDate
            )
            return [meditation, walkDuration]
        case .nutrition:
            if let goalModel = await nutritionGoal(dueDate: dueDate) {
                return [goalModel]
            }
            return []
        case .exerciseEffectiveness:
            return await exerciseEffectivenessGoals(dueDate: dueDate)
        case .bowelMovements:
            return await bowelMovementGoal(dueDate: dueDate)
        }
    }

    func nutritionGoal(dueDate: Date) async -> GoalModel? {
        guard let nutritionSummary = VitalsViewModel.shared.nutritionSummary else { return nil }

        if let macros = nutritionSummary.details.macros {
            let proteinGoal = HealthManager.shared.recommendedDailyProteinPercentOfDietaryEnergy()
            let carbsGoal = HealthManager.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy()
            let fatGoal = HealthManager.shared.recommendedDailyFatPercentOfDietaryEnergy()

            if macros.proteinPercent < proteinGoal.lowerBound {
                return GoalModel(
                    title: "Protein Intake",
                    systemImage: "fork.knife",
                    summary: "Try and increase your protein intake. You can find protein in things like meat, greek yogurt, chickpeas, or edamame.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryProtein, unit: .gram()),
                        unit: .gram(),
                        measurement: .increaseProtein
                    ),
                    vitalKind: .nutrition
                )
            }
            if macros.carbsPercent < carbsGoal.lowerBound {
                return GoalModel(
                    title: "Carbohydrate Intake",
                    systemImage: "fork.knife",
                    summary: "Try and increase your carbohydrate intake. You can get more carbs by eating things like whole wheat bread, potatoes, bananas, or yogurt.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryCarbohydrates, unit: .gram()),
                        unit: .gram(),
                        measurement: .increaseCarbs
                    ),
                    vitalKind: .nutrition
                )
            }
            if macros.fatPercent < fatGoal.lowerBound {
                return GoalModel(
                    title: "Fat Intake",
                    systemImage: "fork.knife",
                    summary: "Focus on increasing your fat intake. Try eating things like avocados, nuts, salmon, eggs, or cheese to get more healthy fat.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryFatTotal, unit: .gram()),
                        unit: .gram(),
                        measurement: .increaseFat
                    ),
                    vitalKind: .nutrition
                )
            }
        }

        if let nutrientGoal = await highestLeverageVitaminMineralOtherNutrientGoal(
            nutritionSummary: nutritionSummary,
            dueDate: dueDate
        ) {
            return nutrientGoal
        }

        return nil
    }

    func highestLeverageVitaminMineralOtherNutrientGoal(
        nutritionSummary: NutritionMonthlySummary,
        dueDate: Date
    ) async -> GoalModel? {
        let microgram = HKUnit.gramUnit(with: .micro)
        let milligram = HKUnit.gramUnit(with: .milli)

        var scoredNutrients = [(Double, GoalModel)]()

        if
            let target = HealthManager.shared.recommendedDailyIntakeForVitaminA(),
            let score = nutritionSummary.details.vitaminAScore
        {
            let goal = GoalModel(
                title: "Vitamin A",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin A levels are low. Try eating things like liver, fish, eggs, dark leafy greens, orange + yellow vegetables, or mangoes.",
                dueDate: dueDate,
                metric: .init(
                    value: await scaledTarget(for: .dietaryVitaminA, unit: microgram),
                    unit: microgram,
                    measurement: .increaseVitaminA
                ),
                vitalKind: .nutrition
            )
//            scoredNutrients.append((score, goal))
        }

        if
            let target = HealthManager.shared.recommendedDailyIntakeForVitaminB6(),
            let score = nutritionSummary.details.vitaminB6Score
        {
            let goal = GoalModel(
                title: "Vitamin B6",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin B6 levels are low. Try eating things like chicken breast, tuna, beef, chickpeas, bananas, spinach, or oatmeal.",
                dueDate: dueDate,
                metric: .init(
                    value: await scaledTarget(for: .dietaryVitaminB6, unit: milligram),
                    unit: milligram,
                    measurement: .increaseVitaminB6
                ),
                vitalKind: .nutrition
            )
//            scoredNutrients.append((score, goal))
        }

        if
            let target = HealthManager.shared.recommendedMinDailyIntakeForVitaminB12(),
            let score = nutritionSummary.details.vitaminB12Score
        {
            let goal = GoalModel(
                title: "Vitamin B12",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin B12 levels are low. Try eating things like red meats, salmon, swiss or mozarella cheeses, yogurt, or egg yolks.",
                dueDate: dueDate,
                metric: .init(
                    value: await scaledTarget(for: .dietaryVitaminB12, unit: microgram),
                    unit: microgram,
                    measurement: .increaseVitaminB12
                ),
                vitalKind: .nutrition
            )
//            scoredNutrients.append((score, goal))
        }

        if
            let target = HealthManager.shared.recommendedDailyIntakeForVitaminC(),
            let score = nutritionSummary.details.vitaminCScore
        {
            let goal = GoalModel(
                title: "Vitamin C",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin C levels are low. Try eating things like citrus fruits, berries, kiwi, cantaloupe, bell peppers, tomatoes, potatoes, or leafy greens.",
                dueDate: dueDate,
                metric: .init(
                    value: await scaledTarget(for: .dietaryVitaminC, unit: milligram),
                    unit: milligram,
                    measurement: .increaseVitaminC
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        // TODO: Check time in sunlight for proper vitamin D level check.
        if
            let target = HealthManager.shared.recommendedDailyIntakeForVitaminD(),
            let score = nutritionSummary.details.vitaminDScore
        {
            let goal = GoalModel(
                title: "Vitamin D",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin D levels are low. Try eating things like salmon, mackerel, cod liver oil, egg yolks, or mushrooms.",
                dueDate: dueDate,
                metric: .init(
                    value: await scaledTarget(for: .dietaryVitaminD, unit: microgram),
                    unit: microgram,
                    measurement: .increaseVitaminD
                ),
                vitalKind: .nutrition
            )
//            scoredNutrients.append((score, goal))
        }

        if
            let target = HealthManager.shared.recommendedDailyIntakeForVitaminE(),
            let score = nutritionSummary.details.vitaminEScore
        {
            let goal = GoalModel(
                title: "Vitamin E",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin E levels are low. Try eating things like nuts, seeds, avocado, mango, spinach, broccoli, or asparagus.",
                dueDate: dueDate,
                metric: .init(
                    value: await scaledTarget(for: .dietaryVitaminE, unit: milligram),
                    unit: milligram,
                    measurement: .increaseVitaminE
                ),
                vitalKind: .nutrition
            )
//            scoredNutrients.append((score, goal))
        }

        if
            let mineral = nutritionSummary.details.averageCalcium,
            let target = HealthManager.shared.recommendedIntakeForCalcium(),
            let score = nutritionSummary.details.calciumScore
        {
            let isBelow = mineral.doubleValue(for: milligram) < target.lowerDoubleValue(for: milligram)
            if isBelow {
                let goal = GoalModel(
                    title: "Calcium Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough calcium. Try eating things like nuts, seeds, avocado, mango, spinach, broccoli, or asparagus.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryCalcium, unit: milligram),
                        unit: milligram,
                        measurement: .increaseCalcium
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            } else {
                let goal = GoalModel(
                    title: "Calcium Intake",
                    systemImage: "arrow.down.circle",
                    summary: "You're getting too much calcium. Try avoiding eating things like nuts, seeds, avocado, mango, spinach, broccoli, or asparagus.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryCalcium, unit: milligram, isincrease: false),
                        unit: milligram,
                        measurement: .decreaseCalcium
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            }
        }

        if
            let mineral = nutritionSummary.details.averageIron,
            let target = HealthManager.shared.recommendedDailyIntakeForIron(),
            let score = nutritionSummary.details.ironScore
        {
            let isBelow = mineral.doubleValue(for: milligram) < target.lowerDoubleValue(for: milligram)
            if isBelow {
                let goal = GoalModel(
                    title: "Iron Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough iron. Try eating things like red meat, poultry, fish, eggs, beans, spinach, cashews, almonds, or dark chocolate.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryIron, unit: milligram),
                        unit: milligram,
                        measurement: .increaseIron
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            } else {
                let goal = GoalModel(
                    title: "Iron Intake",
                    systemImage: "arrow.down.circle",
                    summary: "You're getting too much iron. Try avoiding eating things like red meat, poultry, fish, eggs, beans, spinach, cashews, almonds, or dark chocolate.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryIron, unit: milligram, isincrease: false),
                        unit: milligram,
                        measurement: .decreaseIron
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            }
        }

        if
            let mineral = nutritionSummary.details.averageMagnesium,
            let target = HealthManager.shared.recommendedDailyIntakeForMagnesium(),
            let score = nutritionSummary.details.magnesiumScore
        {
            let isBelow = mineral.doubleValue(for: milligram) < target.lowerDoubleValue(for: milligram)
            if isBelow {
                let goal = GoalModel(
                    title: "Magnesium Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough magnesium. Try eating things like spinach, kale, almonds, whole wheat bread, lentils, chickpeas, salmon, avocados, milk, bananas, or tofu.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryMagnesium, unit: milligram),
                        unit: milligram,
                        measurement: .increaseMagnesium
                    ),
                    vitalKind: .nutrition
                )
//                scoredNutrients.append((score, goal))
            } else {
                let goal = GoalModel(
                    title: "Magnesium Intake",
                    systemImage: "arrow.down.circle",
                    summary: "You're getting too much iron. Try avoiding eating things like spinach, kale, almonds, whole wheat bread, lentils, chickpeas, salmon, avocados, milk, bananas, or tofu.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryMagnesium, unit: milligram, isincrease: false),
                        unit: milligram,
                        measurement: .decreaseMagnesium
                    ),
                    vitalKind: .nutrition
                )
//                scoredNutrients.append((score, goal))
            }
        }

        if
            let mineral = nutritionSummary.details.averagePotassium,
            let target = HealthManager.shared.recommendedDailyIntakeForPotassium(),
            let score = nutritionSummary.details.potassiumScore
        {
            let isBelow = mineral.doubleValue(for: milligram) < target.lowerDoubleValue(for: milligram)
            if isBelow {
                let goal = GoalModel(
                    title: "Potassium Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough potassium. Try eating things like bananas, avocados, potatoes, spinach, tomates, beans, oranges, yogurt, or salmon.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryPotassium, unit: milligram),
                        unit: milligram,
                        measurement: .increasePotassium
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            }
            // We only have the below goal since it's not really possible to get too much potassium.
        }

        if
            let mineral = nutritionSummary.details.averageSodium,
            let target = HealthManager.shared.recommendedDailyIntakeForSodium(),
            let score = nutritionSummary.details.sodiumScore
        {
            let isBelow = mineral.doubleValue(for: milligram) < target.lowerDoubleValue(for: milligram)
            if isBelow {
                let goal = GoalModel(
                    title: "Sodium Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough sodium. Try eating things like processed meats, canned vegetables and soups, cheese, or adding table salt to meals.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietarySodium, unit: milligram),
                        unit: milligram,
                        measurement: .increaseSodium
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            } else {
                let goal = GoalModel(
                    title: "Sodium Intake",
                    systemImage: "arrow.down.circle",
                    summary: "You're getting too much sodium. Try avoiding eating things like processed meats, canned vegetables and soups, cheese, and avoid adding table salt to meals.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietarySodium, unit: milligram, isincrease: false),
                        unit: milligram,
                        measurement: .decreaseSodium
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            }
        }

        if
            let mineral = nutritionSummary.details.averageZinc,
            let target = HealthManager.shared.recommendedDailyIntakeForZinc(),
            let score = nutritionSummary.details.zincScore
        {
            let isBelow = mineral.doubleValue(for: milligram) < target.lowerDoubleValue(for: milligram)
            if isBelow {
                let goal = GoalModel(
                    title: "Zinc Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough zinc. Try eating things like beef, lamb, shellfish, legumes, seeds, nuts, dairy products, eggs, or whole grains.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryZinc, unit: milligram),
                        unit: milligram,
                        measurement: .increaseZinc
                    ),
                    vitalKind: .nutrition
                )
//                scoredNutrients.append((score, goal))
            } else {
                let goal = GoalModel(
                    title: "Zinc Intake",
                    systemImage: "arrow.down.circle",
                    summary: "You're getting too much zinc. Try avoiding eating things like beef, lamb, shellfish, legumes, seeds, nuts, dairy products, eggs, or whole grains.",
                    dueDate: dueDate,
                    metric: .init(
                        value: await scaledTarget(for: .dietaryZinc, unit: milligram, isincrease: false),
                        unit: milligram,
                        measurement: .decreaseZinc
                    ),
                    vitalKind: .nutrition
                )
//                scoredNutrients.append((score, goal))
            }
        }

        if
            let target = HealthManager.shared.recommendedMaxDailyIntakeForSugar(),
            let score = nutritionSummary.details.sugarScore
        {
            let goal = GoalModel(
                title: "Sugar Intake",
                systemImage: "arrow.down.circle",
                summary: "You're eating too much sugar. Try avoiding eating things like sugary snacks or drinks, white bread, pasta, rice, fried foods, desserts, alcohol, or fruit juice. Avoid artificial sweeteners as well, since they can increase sugar cravings and impact gut health.",
                dueDate: dueDate,
                metric: .init(
                    value: await scaledTarget(for: .dietarySugar, unit: .gram(), isincrease: false),
                    unit: .gram(),
                    measurement: .decreaseSugar
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        if
            let target = HealthManager.shared.recommendedMaxDailyCaffeine(),
            let score = nutritionSummary.details.caffeineScore
        {
            let goal = GoalModel(
                title: "Caffeine Intake",
                systemImage: "arrow.down.circle",
                summary: "You're getting too much caffeine. Try avoiding ingesting things like caffeinated beverages (coffee, pop), or chocolate.",
                dueDate: dueDate,
                metric: .init(
                    value: await scaledTarget(for: .dietaryCaffeine, unit: milligram, isincrease: false),
                    unit: milligram,
                    measurement: .decreaseCaffeine
                ),
                vitalKind: .nutrition
            )
//            scoredNutrients.append((score, goal))
        }

        if
            let score = nutritionSummary.details.waterScore
        {
            let goal = await waterGoal(
                summary: "Increase the amount of water you drink to stay hydrated.",
                vitalKind: .nutrition,
                dueDate: dueDate
            )
            scoredNutrients.append((score, goal))
        }

        if
            let target = HealthManager.shared.recommendedMinDailyIntakeForFiber(),
            let score = nutritionSummary.details.fiberScore
        {
            let goal = GoalModel(
                title: "Fiber Intake",
                systemImage: "arrow.up.circle",
                summary: "You're not getting enough fiber. Try eating things like fruits, leafy greens, broccoli, carrots, oats, whole grain bread, beans, almonds, or popcorn.",
                dueDate: dueDate,
                metric: .init(
                    value: await scaledTarget(for: .dietaryFiber, unit: .gram()),
                    unit: .gram(),
                    measurement: .increaseFiber
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        return scoredNutrients.min(by: { $0.0 < $1.0 })?.1
    }

    func scaledTarget(for quantityTypeID: HKQuantityTypeIdentifier, unit: HKUnit, isincrease: Bool = true) async -> Double {
        let averageValue = await HealthManager.shared.fetchNutritionalDailyAverage(
            for: quantityTypeID,
            unit: unit,
            dateRange: .trailingWeeksFromStartOfWeek(.numWeeksPastAverage)
        ).doubleValue(for: unit) * 7 // Gets us a weekly amount

        return multipliedGoal(for: averageValue, isIncrease: isincrease)
    }

    func multipliedGoal(for value: Double, isIncrease: Bool = true) -> Double {
        let dailyValue = value / 7
        let newValue: Double
        if isIncrease {
            newValue = (dailyValue * .goalMultiplier).roundedToNiceNumber() * 7
        } else {
            newValue = (dailyValue / .goalMultiplier).roundedToNiceNumber() * 7
        }

        print("Weekly Avg: \(value), isIncrease: \(isIncrease ? "true" : "false"), goal: \(newValue)")

        return newValue
    }
}

private extension GoalsViewModel {

    func exerciseEffectivenessGoals(dueDate: Date) async -> [GoalModel] {
        guard let exerciseSummary = VitalsViewModel.shared.exerciseEffectivenessSummary else { return [] }

        let reports = await HealthManager.shared.fetchWorkoutHeartRateReports(dateRange: defaultDateRange)
        let distribution = reports.generateOverallDistribution()

        let lastYearReport = await HealthManager.shared.fetchWorkoutHeartRateReports(dateRange: .trailingYearsFromNow(1))
        let lastYearWorkoutTypeReports = lastYearReport.generateWorkoutTypeHeartRateReports()

        let zone12DominantActivities = lastYearWorkoutTypeReports.filter({ typeReport in
            typeReport.heartZoneDistribution.dominantZones.contains(1) ||
            typeReport.heartZoneDistribution.dominantZones.contains(2)
        }).map({ $0.activityType.name })

        let zone12Summary: String
        if let activityList = ListFormatter.main.string(from: zone12DominantActivities) {
            zone12Summary = "Do more workouts where your heart rate falls in zone 1 or 2. Some activities you like to do include \(activityList)."
        } else {
            zone12Summary = "Do more workouts where your heart rate falls in zone 1 or 2."
        }

        let zone12Value = (distribution.zone12Duration.doubleValue(for: .minute()) / Double(Int.numWeeksPastAverage))

        let zone12Goal = GoalModel(
            title: "Time in Zones 1 and 2",
            systemImage: "12.square.fill",
            summary: zone12Summary,
            dueDate: dueDate,
            metric: .init(
                value: multipliedGoal(for: zone12Value),
                unit: .minute(),
                measurement: .targetHeartRateZoneTimeZone12
            ),
            vitalKind: .exerciseEffectiveness
        )

        let zone34DominantActivities = lastYearWorkoutTypeReports.filter({ typeReport in
            typeReport.heartZoneDistribution.dominantZones.contains(3) ||
            typeReport.heartZoneDistribution.dominantZones.contains(4)
        }).map({ $0.activityType.name })

        let zone34Summary: String
        if let activityList = ListFormatter.main.string(from: zone34DominantActivities) {
            zone34Summary = "Do more workouts where your heart rate falls in zone 3 or 4. Some activities you like to do include \(activityList)."
        } else {
            zone34Summary = "Do more workouts where your heart rate falls in zone 3 or 4."
        }

        let zone34Value = (distribution.zone34Duration.doubleValue(for: .minute()) / Double(Int.numWeeksPastAverage))

        let zone34Goal = GoalModel(
            title: "Time in Zones 3 and 4",
            systemImage: "34.square.fill",
            summary: zone34Summary,
            dueDate: dueDate,
            metric: .init(
                value: multipliedGoal(for: zone34Value),
                unit: .minute(),
                measurement: .targetHeartRateZoneTimeZone34
            ),
            vitalKind: .exerciseEffectiveness
        )

        let zone5DominantActivities = lastYearWorkoutTypeReports.filter({ typeReport in
            typeReport.heartZoneDistribution.dominantZones.contains(5)
        }).map({ $0.activityType.name })

        let zone5Summary: String
        if let activityList = ListFormatter.main.string(from: zone5DominantActivities) {
            zone5Summary = "Do more intense workouts where your heart rate falls in zone 5. Some activities you like to do include \(activityList)."
        } else {
            zone5Summary = "Do more intense workouts where your heart rate falls in zone 5."
        }

        let zone5Value = (distribution.zone5.doubleValue(for: .minute()) / Double(Int.numWeeksPastAverage))

        let zone5Goal = GoalModel(
            title: "Time in Zone 5",
            systemImage: "5.square.fill",
            summary: zone5Summary,
            dueDate: dueDate,
            metric: .init(
                value: multipliedGoal(for: zone5Value),
                unit: .minute(),
                measurement: .targetHeartRateZoneTimeZone5
            ),
            vitalKind: .exerciseEffectiveness
        )

        switch exerciseSummary.details.level {
        case .sedentary, .minimal:
            return [zone12Goal]
        case .moderate:
            return [zone34Goal, zone12Goal]
        case .high:
            return [zone5Goal, zone34Goal]
        }
    }
}

private extension GoalsViewModel {

    func bowelMovementGoal(dueDate: Date) async -> [GoalModel] {
        guard let bowelMovementSummary = VitalsViewModel.shared.bowelMovementSummary else { return [] }

        guard let focusStoolType = bowelMovementSummary.details?.prioritizedBristolStoolType() else { return [] }

        let fiberGoal = GoalModel(
            title: "Fiber Intake",
            systemImage: "arrow.up.circle",
            summary: "More fiber could help improve bowel movements. Try eating things like fruits, leafy greens, broccoli, carrots, oats, whole grain bread, beans, almonds, or popcorn.",
            dueDate: dueDate,
            metric: .init(
                value: await scaledTarget(for: .dietaryFiber, unit: .gram()),
                unit: .gram(),
                measurement: .increaseFiber
            ),
            vitalKind: .bowelMovements
        )

        let waterGoal = await waterGoal(
            summary: "Drinking more water can help improve your bowel movements.",
            vitalKind: .bowelMovements,
            dueDate: dueDate
        )

        let walkRunDistance = await walkRunDistanceGoal(
            summary: "Increasing your walking and running distance this week can help you regularize your bowel movements.",
            vitalKind: .bowelMovements,
            dueDate: dueDate
        )

        let steps = await stepGoal(
            summary: "Moving more can help make you more regular. Tracking steps is an easy way to get yourself moving more.",
            vitalKind: .bowelMovements,
            dueDate: dueDate
        )

        let meditationGoal = await meditationGoal(
            summary: "Lowering your stress can help improve your bowel movements. Try and meditate more throughout the week.",
            vitalKind: .bowelMovements,
            dueDate: dueDate
        )

        switch focusStoolType {
        case 1:
            return [waterGoal, fiberGoal]
        case 2:
            return [waterGoal, steps, walkRunDistance, fiberGoal]
        case 5:
            return [fiberGoal, waterGoal]
        case 6:
            return [meditationGoal, waterGoal, fiberGoal]
        case 7:
            return [waterGoal]
        default:
            return []
        }
    }
}

private extension GoalsViewModel {

    var defaultDateRange: DateRange {
        .trailingWeeksFromStartOfWeek(.numWeeksPastAverage)
    }

    func timeInDaylightGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let unit = HKUnit.minute()
        let average = await HealthManager.shared.fetchAverage(
            for: .timeInDaylight,
            unit: unit,
            divisor: Double(Int.numWeeksPastAverage),
            dateRange: .trailingWeeksFromStartOfWeek(.numWeeksPastAverage)
        ).doubleValue(for: unit)

        return GoalModel(
            title: "Sunlight",
            systemImage: "sun.max.fill",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(multipliedGoal(for: average), 105),
                unit: unit,
                measurement: .timeInDaylight
            ),
            vitalKind: vitalKind
        )
    }

    func walkDurationGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let unit = HKUnit.minute()
        let workouts = await HealthManager.shared.fetchWorkouts(
            activityType: .walking,
            dateRange: defaultDateRange
        )
        let averageDuration = workouts.sum(keyPath: \.duration) / Double(Int.numWeeksPastAverage)

        return GoalModel(
            title: "Walking Duration",
            systemImage: "figure.walk",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(multipliedGoal(for: (averageDuration / 60)), 14),
                unit: unit,
                measurement: .walkDuration
            ),
            vitalKind: vitalKind
        )
    }

    func walkRunDistanceGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let unit = HKUnit.meterUnit(with: .kilo)
        let averageQuantity = await HealthManager.shared.fetchAverage(
            for: .distanceWalkingRunning,
            unit: unit,
            divisor: Double(Int.numWeeksPastAverage),
            dateRange: .trailingWeeksFromStartOfWeek(.numWeeksPastAverage)
        )

        let amount = averageQuantity.doubleValue(for: unit)

        return GoalModel(
            title: "Walking + Running Distance",
            systemImage: "figure.walk",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(multipliedGoal(for: amount), 3.5),
                unitString: unit.unitString,
                measurement: .walkRunDistance
            ),
            vitalKind: vitalKind
        )
    }

    func runDistanceGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let workouts = await HealthManager.shared.fetchWorkouts(
            activityType: .running,
            dateRange: .trailingWeeksFromStartOfWeek(.numWeeksPastAverage)
        )
        let unit = HKUnit.meterUnit(with: .kilo)
        let average = workouts.sum { workout in
            workout.totalDistanceWalkingRunning.doubleValue(for: unit)
        } / Double(Int.numWeeksPastAverage)

        return GoalModel(
            title: "Running",
            systemImage: "figure.run",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(multipliedGoal(for: average), 2.1),
                unitString: unit.unitString,
                measurement: .runDistance
            ),
            vitalKind: vitalKind
        )
    }

    func hikeDurationGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let unit = HKUnit.minute()
        let workouts = await HealthManager.shared.fetchWorkouts(
            activityType: .hiking,
            dateRange: defaultDateRange
        )
        let averageDuration = workouts.sum(keyPath: \.duration) / Double(Int.numWeeksPastAverage)

        return GoalModel(
            title: "Hiking",
            systemImage: "figure.hiking",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(multipliedGoal(for: (averageDuration / 60)), 14),
                unit: unit,
                measurement: .hikeDuration
            ),
            vitalKind: vitalKind
        )
    }

    func stepGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let averageQuantity = await HealthManager.shared.fetchAverage(
            for: .stepCount,
            unit: .count(),
            divisor: Double(Int.numWeeksPastAverage),
            dateRange: .trailingWeeksFromStartOfWeek(.numWeeksPastAverage)
        )
        let unit = HKUnit.count()
        let amount = averageQuantity.doubleValue(for: unit)

        return GoalModel(
            title: "Steps",
            systemImage: "figure.walk",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(multipliedGoal(for: amount), 3500),
                unit: unit,
                measurement: .stepCount
            ),
            vitalKind: vitalKind
        )
    }

    func hiitDurationGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let unit = HKUnit.minute()
        let workouts = await HealthManager.shared.fetchWorkouts(
            activityType: .highIntensityIntervalTraining,
            dateRange: defaultDateRange
        )
        let averageDuration = workouts.sum(keyPath: \.duration) / Double(Int.numWeeksPastAverage)

        return GoalModel(
            title: "HIIT Duration",
            systemImage: "figure.highintensity.intervaltraining",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(multipliedGoal(for: (averageDuration / 60)), 35),
                unit: unit,
                measurement: .hiitWorkoutDuration
            ),
            vitalKind: vitalKind
        )
    }

    func meditationGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverageMeditationMinutes(numWeeks: .numWeeksPastAverage)

        return GoalModel(
            title: "Meditation",
            systemImage: "figure.mind.and.body",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(multipliedGoal(for: average), 7),
                unit: .minute(),
                measurement: .meditationMinutes
            ),
            vitalKind: vitalKind
        )
    }

    func waterGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        GoalModel(
            title: "Water",
            systemImage: "waterbottle",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(await scaledTarget(for: .dietaryWater, unit: .literUnit(with: .milli)), 2000),
                unit: .literUnit(with: .milli),
                measurement: .increaseWater
            ),
            vitalKind: vitalKind
        )
    }
}
