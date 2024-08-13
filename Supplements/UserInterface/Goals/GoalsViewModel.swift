//
//  GoalsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import HealthKit

private extension Int {
    static let numWeeksPastAverage: Int = 6
}

private extension Double {
    static let goalMultiplier: Double = 1.3
}

final actor GoalsViewModel: ObservableObject {
    static let shared = GoalsViewModel()

    @MainActor @Published var goals = [GoalModel]() {
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
            let goals = try? JSONDecoder.main.decode([GoalModel].self, from: data)
        {
            await MainActor.run {
                self.goals = goals
            }
        }
    }

    func checkForUpdateGoals(force: Bool = false) async {
        await loadGoals()

        if let goalDueDate = await goals.first?.dueDate {
            if goalDueDate > .now && !force {
                print("Returning early since goals are still valid")
                return
            }
        }

        guard let dueDate = Calendar.current.startOfNextWeek(for: .now) else { return }

        var goals = [GoalModel]()

        var vitalNames = [String]()
        let sortedVitals = VitalsViewModel.shared.vitals.sorted(by: { $0.score < $1.score })
        if let vital = sortedVitals.safeAccess(at: 0), let goal = await goal(for: vital, dueDate: dueDate) {
            goals.append(goal)
            vitalNames.append(vital.id.name)
        }

        if let vital = sortedVitals.safeAccess(at: 1), let goal = await goal(for: vital, dueDate: dueDate) {
            goals.append(goal)
            vitalNames.append(vital.id.name)
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

        await NotificationManager.shared.sendNotification(
            title: "New Goals Available",
            subtitle: subtitle,
            categoryID: .CategoryID.goalsMessage
        )
    }
}

private extension GoalsViewModel {

    func goal(for vital: VitalModel, dueDate: Date) async -> GoalModel? {
        switch vital.id {
        case .sleepQuality:
            return await timeInDaylightGoal(
                summary: "Your sleep scores have been a bit low lately. Try getting some more sunlight than you normally do this week!",
                vitalKind: .sleepQuality,
                dueDate: dueDate
            )
        case .activityLevel:
            return await stepGoal(
                summary: "Let's improve your activty level by incorporating more steps in your day. Walking has numerous other health benefits.",
                vitalKind: .activityLevel,
                dueDate: dueDate
            )
        case .cardioFitness:
            return await runDistanceGoal(
                summary: "Your Cardio Fitness should be your main focus. Let's focus on running more this week.",
                vitalKind: .cardioFitness,
                dueDate: dueDate
            )
        case .bodyComposition:
            return await stepGoal(
                summary: "Your body composition is out of the recommended range. A quick way to start making progess is to increase your steps.",
                vitalKind: .bodyComposition,
                dueDate: dueDate
            )
        case .mobility:
            return await walkRunDistanceGoal(
                summary: "Your mobility should be top of mind for you this week. You can improve your mobility by walking or running more!",
                vitalKind: .mobility,
                dueDate: dueDate
            )
        case .stressLevels:
            return await meditationGoal(
                summary: "Your stress levels are getting quite high. Try incorporating more meditation this week.",
                vitalKind: .stressLevels,
                dueDate: dueDate
            )
        case .nutrition:
            return nutritionGoal(dueDate: dueDate)
        }
    }

    func nutritionGoal(dueDate: Date) -> GoalModel? {
        guard let nutritionSummary = VitalsViewModel.shared.nutritionSummary else { return nil }

        if let macros = nutritionSummary.details.macros {
            let proteinGoal = HealthManager.shared.recommendedDailyProteinPercentOfDietaryEnergy()
            let carbsGoal = HealthManager.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy()
            let fatGoal = HealthManager.shared.recommendedDailyFatPercentOfDietaryEnergy()

            if macros.proteinPercent < proteinGoal.lowerBound {
                return GoalModel(
                    title: "Increase Protein Intake",
                    systemImage: "fork.knife",
                    summary: "Try and increase your protein intake. You can find protein in things like meat, greek yogurt, chickpeas, or edamame.",
                    dueDate: dueDate,
                    metric: .init(
                        value: proteinGoal.lowerBound,
                        measurement: .increaseProtein
                    ),
                    vitalKind: .nutrition
                )
            }
            if macros.carbsPercent < carbsGoal.lowerBound {
                return GoalModel(
                    title: "Increase Carbohydrate Intake",
                    systemImage: "fork.knife",
                    summary: "Try and increase your carbohydrate intake. You can get more carbs by eating things like whole wheat bread, potatoes, bananas, or yogurt.",
                    dueDate: dueDate,
                    metric: .init(
                        value: carbsGoal.lowerBound,
                        measurement: .increaseCarbs
                    ),
                    vitalKind: .nutrition
                )
            }
            if macros.fatPercent < fatGoal.lowerBound {
                return GoalModel(
                    title: "Increase Fat Intake",
                    systemImage: "fork.knife",
                    summary: "Focus on increasing your fat intake. Try eating things like avocados, nuts, salmon, eggs, or cheese to get more healthy fat.",
                    dueDate: dueDate,
                    metric: .init(
                        value: carbsGoal.lowerBound,
                        measurement: .increaseCarbs
                    ),
                    vitalKind: .nutrition
                )
            }
        }

        if let nutrientGoal = highestLeverageVitaminMineralOtherNutrientGoal(nutritionSummary: nutritionSummary, dueDate: dueDate) {
            return nutrientGoal
        }

        return nil
    }

    func highestLeverageVitaminMineralOtherNutrientGoal(
        nutritionSummary: NutritionMonthlySummary,
        dueDate: Date
    ) -> GoalModel? {
        let microgram = HKUnit.gramUnit(with: .micro)
        let milligram = HKUnit.gramUnit(with: .milli)

        var scoredNutrients = [(Double, GoalModel)]()

        if
            let nutrient = nutritionSummary.details.averageVitaminA,
            let target = HealthManager.shared.recommendedDailyIntakeForVitaminA(),
            let score = nutritionSummary.details.vitaminAScore
        {
            let goal = GoalModel(
                title: "Get More Vitamin A",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin A levels are low. Try eating things like liver, fish, eggs, dark leafy greens, orange + yellow vegetables, or mangoes.",
                dueDate: dueDate,
                metric: .init(
                    value: target.lowerDoubleValue(for: microgram),
                    measurement: .increaseVitaminA
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        if
            let vitamin = nutritionSummary.details.averageVitaminB6,
            let target = HealthManager.shared.recommendedDailyIntakeForVitaminB6(),
            let score = nutritionSummary.details.vitaminB6Score
        {
            let goal = GoalModel(
                title: "Get More Vitamin B6",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin B6 levels are low. Try eating things like chicken breast, tuna, beef, chickpeas, bananas, spinach, or oatmeal.",
                dueDate: dueDate,
                metric: .init(
                    value: target.lowerDoubleValue(for: milligram),
                    measurement: .increaseVitaminB6
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        if
            let vitamin = nutritionSummary.details.averageVitaminB12,
            let target = HealthManager.shared.recommendedMinDailyIntakeForVitaminB12(),
            let score = nutritionSummary.details.vitaminB12Score
        {
            let goal = GoalModel(
                title: "Get More Vitamin B12",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin B12 levels are low. Try eating things like red meats, salmon, swiss or mozarella cheeses, yogurt, or egg yolks.",
                dueDate: dueDate,
                metric: .init(
                    value: target.doubleValue(for: microgram),
                    measurement: .increaseVitaminB12
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        if
            let vitamin = nutritionSummary.details.averageVitaminC,
            let target = HealthManager.shared.recommendedDailyIntakeForVitaminC(),
            let score = nutritionSummary.details.vitaminCScore
        {
            let goal = GoalModel(
                title: "Get More Vitamin C",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin C levels are low. Try eating things like citrus fruits, berries, kiwi, cantaloupe, bell peppers, tomatoes, potatoes, or leafy greens.",
                dueDate: dueDate,
                metric: .init(
                    value: target.lowerDoubleValue(for: milligram),
                    measurement: .increaseVitaminC
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        // TODO: Check time in sunlight for proper vitamin D level check.
        if
            let vitamin = nutritionSummary.details.averageVitaminD,
            let target = HealthManager.shared.recommendedDailyIntakeForVitaminD(),
            let score = nutritionSummary.details.vitaminDScore
        {
            let goal = GoalModel(
                title: "Get More Vitamin D",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin D levels are low. Try eating things like salmon, mackerel, cod liver oil, egg yolks, or mushrooms.",
                dueDate: dueDate,
                metric: .init(
                    value: target.lowerDoubleValue(for: microgram),
                    measurement: .increaseVitaminD
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        if
            let vitamin = nutritionSummary.details.averageVitaminE,
            let target = HealthManager.shared.recommendedDailyIntakeForVitaminE(),
            let score = nutritionSummary.details.vitaminEScore
        {
            let goal = GoalModel(
                title: "Get More Vitamin E",
                systemImage: "arrow.up.circle",
                summary: "Your Vitamin E levels are low. Try eating things like nuts, seeds, avocado, mango, spinach, broccoli, or asparagus.",
                dueDate: dueDate,
                metric: .init(
                    value: target.lowerDoubleValue(for: milligram),
                    measurement: .increaseVitaminE
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        if
            let mineral = nutritionSummary.details.averageCalcium,
            let target = HealthManager.shared.recommendedIntakeForCalcium(),
            let score = nutritionSummary.details.calciumScore
        {
            let isBelow = mineral.doubleValue(for: milligram) < target.lowerDoubleValue(for: milligram)
            if isBelow {
                let goal = GoalModel(
                    title: "Increase Calcium Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough calcium. Try eating things like nuts, seeds, avocado, mango, spinach, broccoli, or asparagus.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.lowerDoubleValue(for: milligram),
                        measurement: .increaseCalcium
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            } else {
                let goal = GoalModel(
                    title: "Decrease Calcium Intake",
                    systemImage: "arrow.down.circle",
                    summary: "You're getting too much calcium. Try avoiding eating things like nuts, seeds, avocado, mango, spinach, broccoli, or asparagus.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.upperDoubleValue(for: milligram),
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
                    title: "Increase Iron Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough iron. Try eating things like red meat, poultry, fish, eggs, beans, spinach, cashews, almonds, or dark chocolate.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.lowerDoubleValue(for: milligram),
                        measurement: .increaseIron
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            } else {
                let goal = GoalModel(
                    title: "Decrease Iron Intake",
                    systemImage: "arrow.down.circle",
                    summary: "You're getting too much iron. Try avoiding eating things like red meat, poultry, fish, eggs, beans, spinach, cashews, almonds, or dark chocolate.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.upperDoubleValue(for: milligram),
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
                    title: "Increase Magnesium Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough magnesium. Try eating things like spinach, kale, almonds, whole wheat bread, lentils, chickpeas, salmon, avocados, milk, bananas, or tofu.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.lowerDoubleValue(for: milligram),
                        measurement: .increaseMagnesium
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            } else {
                let goal = GoalModel(
                    title: "Decrease Magnesium Intake",
                    systemImage: "arrow.down.circle",
                    summary: "You're getting too much iron. Try avoiding eating things like spinach, kale, almonds, whole wheat bread, lentils, chickpeas, salmon, avocados, milk, bananas, or tofu.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.upperDoubleValue(for: milligram),
                        measurement: .decreaseMagnesium
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
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
                    title: "Increase Potassium Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough potassium. Try eating things like bananas, avocados, potatoes, spinach, tomates, beans, oranges, yogurt, or salmon.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.lowerDoubleValue(for: milligram),
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
                    title: "Increase Sodium Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough sodium. Try eating things like processed meats, canned vegetables and soups, cheese, or adding table salt to meals.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.lowerDoubleValue(for: milligram),
                        measurement: .increaseSodium
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            } else {
                let goal = GoalModel(
                    title: "Decrease Sodium Intake",
                    systemImage: "arrow.down.circle",
                    summary: "You're getting too much sodium. Try avoiding eating things like processed meats, canned vegetables and soups, cheese, and avoid adding table salt to meals.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.upperDoubleValue(for: milligram),
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
                    title: "Increase Zinc Intake",
                    systemImage: "arrow.up.circle",
                    summary: "You're not getting enough zinc. Try eating things like beef, lamb, shellfish, legumes, seeds, nuts, dairy products, eggs, or whole grains.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.lowerDoubleValue(for: milligram),
                        measurement: .increaseZinc
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            } else {
                let goal = GoalModel(
                    title: "Decrease Zinc Intake",
                    systemImage: "arrow.down.circle",
                    summary: "You're getting too much zinc. Try avoiding eating things like beef, lamb, shellfish, legumes, seeds, nuts, dairy products, eggs, or whole grains.",
                    dueDate: dueDate,
                    metric: .init(
                        value: target.upperDoubleValue(for: milligram),
                        measurement: .decreaseZinc
                    ),
                    vitalKind: .nutrition
                )
                scoredNutrients.append((score, goal))
            }
        }

        if
            let mineral = nutritionSummary.details.averageSugar,
            let target = HealthManager.shared.recommendedMaxDailyIntakeForSugar(),
            let score = nutritionSummary.details.sugarScore
        {
            let goal = GoalModel(
                title: "Decrease Sugar Intake",
                systemImage: "arrow.up.circle",
                summary: "You're eating too much sugar. Try avoiding eating things like sugary snacks or drinks, white bread, pasta, rice, fried foods, desserts, alcohol, or fruit juice. Avoid artificial sweeteners as well, since they can increase sugar cravings and impact gut health.",
                dueDate: dueDate,
                metric: .init(
                    value: target.doubleValue(for: .gram()),
                    measurement: .decreaseSugar
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        if
            let mineral = nutritionSummary.details.averageCaffeine,
            let target = HealthManager.shared.recommendedMaxDailyCaffeine(),
            let score = nutritionSummary.details.caffeineScore
        {
            let goal = GoalModel(
                title: "Decrease Caffeine Intake",
                systemImage: "arrow.up.circle",
                summary: "You're getting too much caffeine. Try avoiding ingesting things like caffeinated beverages (coffee, pop), or chocolate.",
                dueDate: dueDate,
                metric: .init(
                    value: target.doubleValue(for: .gramUnit(with: .milli)),
                    measurement: .decreaseCaffeine
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        if
            let mineral = nutritionSummary.details.averageFiber,
            let target = HealthManager.shared.recommendedMinDailyIntakeForFiber(),
            let score = nutritionSummary.details.fiberScore
        {
            let goal = GoalModel(
                title: "Increase Fiber Intake",
                systemImage: "arrow.up.circle",
                summary: "You're not getting enough fiber. Try eating things like fruits, leafy greens, broccoli, carrots, oats, whole grain bread, beans, almonds, or popcorn.",
                dueDate: dueDate,
                metric: .init(
                    value: target.doubleValue(for: .gram()),
                    measurement: .increaseFiber
                ),
                vitalKind: .nutrition
            )
            scoredNutrients.append((score, goal))
        }

        return scoredNutrients.min(by: { $0.0 < $1.0 })?.1
    }
}

private extension GoalsViewModel {

    func timeInDaylightGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverage(
            for: .timeInDaylight,
            unit: .minute(),
            numWeeks: .numWeeksPastAverage
        )

        return GoalModel(
            title: "Get More Sunlight",
            systemImage: "sun.max.fill",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(average * .goalMultiplier, 200),
                measurement: .timeInDaylight
            ),
            vitalKind: vitalKind
        )
    }

    func walkRunDistanceGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverage(
            for: .distanceWalkingRunning,
            unit: .meterUnit(with: .kilo),
            numWeeks: .numWeeksPastAverage
        )

        return GoalModel(
            title: "Increase Walking + Running Distance",
            systemImage: "figure.walk",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(average * .goalMultiplier, 1),
                measurement: .walkRunDistance
            ),
            vitalKind: vitalKind
        )
    }

    func runDistanceGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let workouts = await HealthManager.shared.fetchWorkoutSummaries(
            activityType: .running,
            numWeeks: .numWeeksPastAverage
        )

        let average = workouts.sum(keyPath: \.distance) / Double(Int.numWeeksPastAverage)

        return GoalModel(
            title: "Run For Longer Distances",
            systemImage: "figure.run",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(average * .goalMultiplier, 2),
                measurement: .runDistance
            ),
            vitalKind: vitalKind
        )
    }

    func stepGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverage(
            for: .stepCount,
            unit: .count(),
            numWeeks: .numWeeksPastAverage
        )

        return GoalModel(
            title: "Increase Step Count",
            systemImage: "figure.walk",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(average * .goalMultiplier, 1000),
                measurement: .stepCount
            ),
            vitalKind: vitalKind
        )
    }

    func meditationGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverageMeditationMinutes(numWeeks: .numWeeksPastAverage)

        return GoalModel(
            title: "Meditate More Often",
            systemImage: "figure.mind.and.body",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(average * .goalMultiplier, 10),
                measurement: .meditationMinutes
            ),
            vitalKind: vitalKind
        )
    }
}
