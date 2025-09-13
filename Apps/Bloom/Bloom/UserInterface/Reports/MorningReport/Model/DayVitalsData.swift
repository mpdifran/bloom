//
//  DayVitalsData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation

struct DayVitalsData: SendableNetworkModel {
  let date: Date
  let activity: ActivityData?
  let bodyComposition: BodyCompositionData?
  let heartHealth: HeartHealthData?
  let nutrition: NutritionData?
  let sleep: SleepData?
  let stress: StressData?
  let exercise: ExerciseData?
  let trainingLoad: TrainingLoadData?
}