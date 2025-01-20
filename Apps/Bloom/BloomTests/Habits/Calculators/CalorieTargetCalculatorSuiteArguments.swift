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
@testable import Bloom

extension CalorieTargetCalculatorTestSuite {

  static var noExistingHabitsArguments: [(Input, Double)] {
    [
      (Input(
        "Light Activity lose weight moderately",
        dietary: 1700,
        bodyMass: 167,
        height: 168,
        age: 30,
        sex: .female,
        targetWeight: 145,
        activityLevel: .light,
        goal: .loseWeight,
        speed: .moderate
      ), 1550), // 1496.5 * 1.375 - 250 (moderate deficit)
      (Input(
        "Sedentary lose weight slowly",
        dietary: 2080,
        bodyMass: 160,
        height: 165,
        age: 30,
        sex: .female,
        targetWeight: 140,
        activityLevel: .sedentary,
        goal: .loseWeight,
        speed: .slow
      ), 1475), // 1445.95 * 1.2 - 150 (slow deficit)
      (Input(
        "High activity maintain weight",
        dietary: 2720,
        bodyMass: 160,
        height: 165,
        age: 30,
        sex: .female,
        targetWeight: 160,
        activityLevel: .high,
        goal: .maintainWeight,
        speed: .slow
      ), 2495), // 1445.95 * 1.725
      (Input(
        "High activity gain weight",
        dietary: 2600,
        bodyMass: 160,
        height: 165,
        age: 30,
        sex: .female,
        targetWeight: 180,
        activityLevel: .high,
        goal: .gainWeight,
        speed: .slow
      ), 2750), // 1445.95 * 1.725 + 250 (surplus)
      (Input(
        "Sedentary lose weight slowly 220 lbs",
        dietary: 2860,
        bodyMass: 220,
        height: 170,
        age: 30,
        sex: .female,
        targetWeight: 140,
        activityLevel: .sedentary,
        goal: .loseWeight,
        speed: .slow
      ), 1850), // 1749.4 * 1.2 - 150
      (Input(
        "Lose weight high activity existing habit",
        dietary: 2000,
        bodyMass: 180,
        height: 170,
        age: 30,
        sex: .female,
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
      ), 2200), // Keep existing habit value
      (Input(
        "Maintain weight high activity existing habit",
        dietary: 2000,
        bodyMass: 180,
        height: 170,
        age: 30,
        sex: .female,
        targetWeight: 180,
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
      ), 2700), // BMR * 1.725 for maintenance
      (Input(
        "Client Data Slow",
        dietary: 2000,
        bodyMass: 153,
        height: 155,
        age: 32,
        sex: .female,
        targetWeight: 130,
        activityLevel: .light,
        goal: .loseWeight,
        speed: .slow,
        existingHabit: nil
      ), 1600),
      (Input(
        "Client Data Moderate",
        dietary: 2000,
        bodyMass: 153,
        height: 155,
        age: 32,
        sex: .female,
        targetWeight: 130,
        activityLevel: .light,
        goal: .loseWeight,
        speed: .moderate,
        existingHabit: nil
      ), 1350),
      (Input(
        "Client Data Fast",
        dietary: 2000,
        bodyMass: 153,
        height: 155,
        age: 32,
        sex: .female,
        targetWeight: 130,
        activityLevel: .light,
        goal: .loseWeight,
        speed: .fast,
        existingHabit: nil
      ), 1200),
      (Input(
        "Client Data Maintain",
        dietary: 2000,
        bodyMass: 153,
        height: 155,
        age: 32,
        sex: .female,
        targetWeight: 130,
        activityLevel: .light,
        goal: .maintainWeight,
        speed: .slow,
        existingHabit: nil
      ), 1850),
      (Input(
        "Client Data Gain Slow",
        dietary: 2000,
        bodyMass: 153,
        height: 155,
        age: 32,
        sex: .female,
        targetWeight: 130,
        activityLevel: .light,
        goal: .gainWeight,
        speed: .slow,
        existingHabit: nil
      ), 2100),
      (Input(
        "Client Data Gain Moderate",
        dietary: 2000,
        bodyMass: 153,
        height: 155,
        age: 32,
        sex: .female,
        targetWeight: 130,
        activityLevel: .light,
        goal: .gainWeight,
        speed: .moderate,
        existingHabit: nil
      ), 2350),
      (Input(
        "Client Data Gain Fast",
        dietary: 2000,
        bodyMass: 153,
        height: 155,
        age: 32,
        sex: .female,
        targetWeight: 130,
        activityLevel: .light,
        goal: .gainWeight,
        speed: .fast,
        existingHabit: nil
      ), 2850),
    ]
  }
}
