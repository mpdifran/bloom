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
    NavigationStack {
      ScrollView {
        VStack {
          endButton

          if workoutManager.sessionState == .running {
            pauseButton
          } else {
            resumeButton
          }
        }
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
}

#Preview {
  PreviewEnvironment {
    ActiveWorkoutControlsView()
  }
}
