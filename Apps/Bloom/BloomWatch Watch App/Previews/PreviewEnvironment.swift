//
//  PreviewEnvironment.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI
import CoreHealth
import HealthKit

struct PreviewEnvironment<Content>: View where Content: View {
  let content: () -> Content

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  private let workoutManager = WorkoutManager.shared

  var body: some View {
    content()
      .environmentObject(workoutManager)
  }
}

struct WorkoutStarterModifier: ViewModifier {
  let activityType: HKWorkoutActivityType
  let locationType: HKWorkoutSessionLocationType

  @EnvironmentObject var workoutManager: WorkoutManager

  func body(content: Content) -> some View {
    content.task {
      let configuration = HKWorkoutConfiguration()
      configuration.activityType = activityType
      configuration.locationType = locationType
      // Use startWorkout to skip countdown in previews
      try? await workoutManager.prepareWorkout(workoutConfiguration: configuration, shouldMirror: false)
    }
  }
}

extension View {

  func preview_startWorkout(
    activityType: HKWorkoutActivityType,
    locationType: HKWorkoutSessionLocationType = .indoor
  ) -> some View {
    modifier(WorkoutStarterModifier(activityType: activityType, locationType: locationType))
  }
}
