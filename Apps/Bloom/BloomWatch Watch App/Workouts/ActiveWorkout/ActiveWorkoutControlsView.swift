//
//  ActiveWorkoutControlsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI
import HealthKit
import CoreHealth
import SFSafeSymbols

struct ActiveWorkoutControlsView: View {
  @EnvironmentObject var workoutManager: WorkoutManager

  var body: some View {
    VStack {
      Button {
        startWorkout()
      } label: {
        Label("Start", systemSymbol: .playFill)
      }
      .disabled(workoutManager.sessionState.isActive)
      .tint(.green)

      Button {
        workoutManager.sessionState == .running ? workoutManager.session?.pause() : workoutManager.session?.resume()
      } label: {
        let title = workoutManager.sessionState == .running ? "Pause" : "Resume"
        let systemSymbol: SFSymbol = workoutManager.sessionState == .running ? .pauseFill : .playFill
        Label(title, systemSymbol: systemSymbol)
      }
      .disabled(!workoutManager.sessionState.isActive)
      .tint(.blue)

      Button {
        workoutManager.session?.stopActivity(with: .now)
      } label: {
        Label("End", systemSymbol: .xmarkApp)
      }
      .tint(.red)
      .disabled(!workoutManager.sessionState.isActive)
    }
  }

  private func startWorkout() {
    Task {
      do {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor
        try await workoutManager.startWorkout(workoutConfiguration: configuration)
      } catch {
        print("Failed to start workout \(error))")
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    ActiveWorkoutControlsView()
  }
}
