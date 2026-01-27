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
  @Environment(\.dismiss) private var dismiss

  @State private var showWorkoutPicker = false
  @State private var isSwitching = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          newWorkoutButton

          if workoutManager.sessionState == .running {
            pauseButton
          } else {
            resumeButton
          }

          endButton
        }
      }
    }
    .sheet(isPresented: $showWorkoutPicker) {
      WorkoutPickerView { variant in
        switchToWorkout(variant: variant)
      }
    }
    .overlay {
      if isSwitching {
        switchingOverlay
      }
    }
  }
}

private extension ActiveWorkoutControlsView {

  var pauseButton: some View {
    Button {
      workoutManager.session?.pause()
    } label: {
      Label("Pause", systemSymbol: .pause)
    }
    .tint(.yellow)
    .bold()
  }

  var resumeButton: some View {
    Button {
      workoutManager.session?.resume()
    } label: {
      Label("Resume", systemSymbol: .play)
    }
    .tint(.green)
    .bold()
  }

  var endButton: some View {
    Button {
      workoutManager.session?.stopActivity(with: .now)
    } label: {
      Label("End", systemSymbol: .xmark)
    }
    .tint(.red)
    .bold()
  }

  var newWorkoutButton: some View {
    Button {
      showWorkoutPicker = true
    } label: {
      Label("New Workout", systemSymbol: .plus)
    }
    .tint(.blue)
    .bold()
  }

  @ViewBuilder
  var switchingOverlay: some View {
    ZStack {
      Color.black.opacity(0.8)
      VStack(spacing: 12) {
        ProgressView()
        Text("Switching...")
          .font(.caption)
      }
    }
    .ignoresSafeArea()
  }

  func switchToWorkout(variant: WorkoutVariant) {
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = variant.activityType
    configuration.locationType = variant.locationType

    if variant.activityType == .swimming {
      configuration.swimmingLocationType = variant.locationType == .indoor ? .pool : .openWater
    }

    isSwitching = true
    showWorkoutPicker = false

    Task {
      do {
        _ = try await workoutManager.switchWorkout(to: configuration)
        await MainActor.run {
          dismiss()
        }
      } catch {
        print("Failed to switch workout: \(error)")
      }
      await MainActor.run {
        isSwitching = false
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    ActiveWorkoutControlsView()
  }
}
