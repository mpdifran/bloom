//
//  SocketMessageWorkoutPlan+Save.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-02-11.
//

import Foundation
import BloomModel
import DataContainer
import SwiftData

extension SocketMessage.WorkoutPlan {

  @MainActor
  func saveToSwiftData(modelContext: ModelContext) throws {
    try modelContext.savingTransaction {
      var sets = [WorkoutSet]()

      for (setIndex, set) in self.sets.enumerated() {
        var exercises = [WorkoutExercise]()
        for (exerciseIndex, exercise) in set.exercises.enumerated() {
          exercises.append(
            WorkoutExercise(
              id: UUID().uuidString,
              index: exerciseIndex,
              title: exercise.title,
              summary: exercise.instructions,
              numberOfReps: exercise.numberOfReps,
              distance: exercise.distance,
              distanceUnit: exercise.distanceUnit?.swiftDataUnit,
              duration: exercise.duration,
              kind: .exercise
            )
          )
        }

        let workoutSet = WorkoutSet(
          id: UUID().uuidString,
          index: setIndex,
          title: set.title,
          focus: set.focus,
          numberOfSets: set.numberOfSets,
          format: set.format.hkFormat,
          duration: set.duration,
          restBetweenExercises: set.restBetweenExercises,
          appleWorkoutType: set.appleWorkoutType.hkWorkoutType
        )
        workoutSet.exercises = exercises
        sets.append(workoutSet)
      }

      let workoutPlanModel = WorkoutPlan(
        id: UUID().uuidString,
        title: title,
        summary: summary,
        creationDate: .now,
        requiredEquipment: requiredEquipment.map({ $0.hkEquipment })
      )
      workoutPlanModel.sets = sets

      modelContext.insert(workoutPlanModel)
    }
  }
}
