//
//  CalorieTargetCalculatorSuiteArguments.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-03.
//

import Testing
import HealthKit
import DataContainer
import BloomFoundation
@testable import Supplements

extension CalorieTargetCalculatorTestSuite {

    static var noExistinHabitsArguments: [(Input, Double)] {
        [
            (Input(
                "Sedentary lose weight slowly",
                dietary: 2080,
                bodyMass: 160,
                targetWeight: 140,
                activityLevel: .sedentary,
                goal: .loseWeight,
                speed: .slow
            ), 1900),
            (Input(
                "Light lose weight slowly",
                dietary: 2400,
                bodyMass: 160,
                targetWeight: 140,
                activityLevel: .light,
                goal: .loseWeight,
                speed: .slow
            ), 2200),
            (Input(
                "High lose weight slowly",
                dietary: 2720,
                bodyMass: 160,
                targetWeight: 140,
                activityLevel: .high,
                goal: .loseWeight,
                speed: .slow
            ), 2600),
            (Input(
                "Sedentary lose weight moderately",
                dietary: 2080,
                bodyMass: 160,
                targetWeight: 140,
                activityLevel: .sedentary,
                goal: .loseWeight,
                speed: .moderate
            ), 1800),
            (Input(
                "Light lose weight moderately",
                dietary: 2400,
                bodyMass: 160,
                targetWeight: 140,
                activityLevel: .light,
                goal: .loseWeight,
                speed: .moderate
            ), 2080),
            (Input(
                "High lose weight moderatly",
                dietary: 2600,
                bodyMass: 160,
                targetWeight: 140,
                activityLevel: .high,
                goal: .loseWeight,
                speed: .moderate
            ), 2400),
            (Input(
                "Sedentary lose weight slowly 220 lbs",
                dietary: 2860,
                bodyMass: 220,
                targetWeight: 140,
                activityLevel: .sedentary,
                goal: .loseWeight,
                speed: .slow
            ), 2600),
            (Input(
                "Sedentary maintain weight 220 lbs",
                dietary: 2860,
                bodyMass: 220,
                targetWeight: 220,
                activityLevel: .sedentary,
                goal: .maintainWeight,
                speed: .slow
            ), 2900),
            (Input(
                "Sedentary gain weight 220 lbs",
                dietary: 2860,
                bodyMass: 220,
                targetWeight: 240,
                activityLevel: .sedentary,
                goal: .gainWeight,
                speed: .slow
            ), 3700),
            (Input(
                "Dietary lose weight slow",
                dietary: 2000,
                bodyMass: 160,
                targetWeight: 140,
                activityLevel: .sedentary,
                goal: .loseWeight,
                speed: .slow
            ), 1900),
            (Input(
                "Dietary lose weight moderate",
                dietary: 2000,
                bodyMass: 160,
                targetWeight: 140,
                activityLevel: .sedentary,
                goal: .loseWeight,
                speed: .moderate
            ), 1800),
            (Input(
                "Dietary lose weight fast",
                dietary: 2000,
                bodyMass: 160,
                targetWeight: 140,
                activityLevel: .sedentary,
                goal: .loseWeight,
                speed: .fast
            ), 1600),
            (Input(
                "Lose weight high activity existing habit",
                dietary: 2000,
                bodyMass: 180,
                targetWeight: 140,
                activityLevel: .high,
                goal: .loseWeight,
                speed: .moderate,
                existingHabit: HabitDTO(
                    id: nil,
                    targetMetric: .calories,
                    value: 1650,
                    unitString: HKUnit.largeCalorie().unitString,
                    startDate: .now,
                    endDate: nil,
                    lastNotificationDate: nil,
                    isSuggested: true,
                    isUserEdited: false,
                    vitalKind: .nutrition,
                    context: ""
                )
            ),
            1650),
            (Input(
                "Maintain weight high activity existing habit",
                dietary: 2000,
                bodyMass: 180,
                targetWeight: 140,
                activityLevel: .high,
                goal: .maintainWeight,
                speed: .moderate,
                existingHabit: HabitDTO(
                    id: nil,
                    targetMetric: .calories,
                    value: 1650,
                    unitString: HKUnit.largeCalorie().unitString,
                    startDate: .now,
                    endDate: nil,
                    lastNotificationDate: nil,
                    isSuggested: true,
                    isUserEdited: false,
                    vitalKind: .nutrition,
                    context: ""
                )
            ),
            3100),
        ]
    }
}
