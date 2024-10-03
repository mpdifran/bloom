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

extension CalorieTargetCalculatorSuite {

    static var noExistinHabitsArguments: [(Input, Double)] {
        [
            (Input(
                "Sedentary lose weight slowly",
                basal: 1800,
                active: 200,
                dietary: 2100,
                bodyMass: 160,
                activityLevel: nil,
                goal: .loseWeight,
                speed: .slow
            ), 1900),
            (Input(
                "Sedentary lose weight moderate",
                basal: 1800,
                active: 200,
                dietary: 2100,
                bodyMass: 160,
                activityLevel: nil,
                goal: .loseWeight,
                speed: .moderate
            ), 1800),
            (Input(
                "Sedentary lose weight fast",
                basal: 1800,
                active: 200,
                dietary: 2100,
                bodyMass: 160,
                activityLevel: nil,
                goal: .loseWeight,
                speed: .fast
            ), 1700),
            (Input(
                "Sedentary maintain weight",
                basal: 1800,
                active: 200,
                dietary: 2100,
                bodyMass: 160,
                activityLevel: nil,
                goal: .maintainWeight,
                speed: .fast
            ), 2000),
            (Input(
                "Sedentary gain weight",
                basal: 1800,
                active: 200,
                dietary: 2100,
                bodyMass: 160,
                activityLevel: nil,
                goal: .gainWeight,
                speed: .fast
            ), 2200),
            (Input(
                "Light Activity lose weight slowly",
                basal: 1800,
                active: 400,
                dietary: 2400,
                bodyMass: 160,
                activityLevel: nil,
                goal: .loseWeight,
                speed: .slow
            ), 2090),
            (Input(
                "AL Sedentary lose weight slowly",
                basal: nil,
                active: nil,
                dietary: 2080,
                bodyMass: 160,
                activityLevel: .sedentary,
                goal: .loseWeight,
                speed: .slow
            ), 1900),
            (Input(
                "AL Light lose weight slowly",
                basal: nil,
                active: nil,
                dietary: 2400,
                bodyMass: 160,
                activityLevel: .light,
                goal: .loseWeight,
                speed: .slow
            ), 2200),
            (Input(
                "AL High lose weight slowly",
                basal: nil,
                active: nil,
                dietary: 2720,
                bodyMass: 160,
                activityLevel: .high,
                goal: .loseWeight,
                speed: .slow
            ), 2600),
            (Input(
                "AL Sedentary lose weight moderately",
                basal: nil,
                active: nil,
                dietary: 2080,
                bodyMass: 160,
                activityLevel: .sedentary,
                goal: .loseWeight,
                speed: .moderate
            ), 1800),
            (Input(
                "AL Light lose weight moderately",
                basal: nil,
                active: nil,
                dietary: 2400,
                bodyMass: 160,
                activityLevel: .light,
                goal: .loseWeight,
                speed: .moderate
            ), 2080),
            (Input(
                "AL High lose weight moderatly",
                basal: nil,
                active: nil,
                dietary: 2600,
                bodyMass: 160,
                activityLevel: .high,
                goal: .loseWeight,
                speed: .moderate
            ), 2400),
            (Input(
                "AL Sedentary lose weight slowly 220 lbs",
                basal: nil,
                active: nil,
                dietary: 2860,
                bodyMass: 220,
                activityLevel: .sedentary,
                goal: .loseWeight,
                speed: .slow
            ), 2600),
            (Input(
                "AL Sedentary maintain weight 220 lbs",
                basal: nil,
                active: nil,
                dietary: 2860,
                bodyMass: 220,
                activityLevel: .sedentary,
                goal: .maintainWeight,
                speed: .slow
            ), 2900),
            (Input(
                "AL Sedentary gain weight 220 lbs",
                basal: nil,
                active: nil,
                dietary: 2860,
                bodyMass: 220,
                activityLevel: .sedentary,
                goal: .gainWeight,
                speed: .slow
            ), 3700),
            (Input(
                "Dietary lose weight slow",
                basal: nil,
                active: nil,
                dietary: 2000,
                bodyMass: 160,
                activityLevel: nil,
                goal: .loseWeight,
                speed: .slow
            ), 1900),
            (Input(
                "Dietary lose weight moderate",
                basal: nil,
                active: nil,
                dietary: 2000,
                bodyMass: 160,
                activityLevel: nil,
                goal: .loseWeight,
                speed: .moderate
            ), 1800),
            (Input(
                "Dietary lose weight fast",
                basal: nil,
                active: nil,
                dietary: 2000,
                bodyMass: 160,
                activityLevel: nil,
                goal: .loseWeight,
                speed: .fast
            ), 1700),
        ]
    }
}
