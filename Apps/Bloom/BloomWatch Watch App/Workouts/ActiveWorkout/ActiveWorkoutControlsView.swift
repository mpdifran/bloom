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
      HStack {
        endButton

        if workoutManager.sessionState == .running {
          pauseButton
        } else {
          resumeButton
        }
      }
      Spacer()
    }
  }
}

private extension ActiveWorkoutControlsView {

  var pauseButton: some View {
    VStack {
      Button {
        workoutManager.session?.pause()
      } label: {
        Image(systemSymbol: .pause)
      }
      .tint(.yellow)
      .bold()
      .font(.title2)

      Text("Pause")
    }
  }

  var resumeButton: some View {
    VStack {
      Button {
        workoutManager.session?.resume()
      } label: {
        Image(systemSymbol: .play)
      }
      .tint(.green)
      .bold()
      .font(.title2)

      Text("Resume")
    }
  }

  var endButton: some View {
    VStack {
      Button {
        workoutManager.session?.stopActivity(with: .now)
      } label: {
        Image(systemSymbol: .xmark)
      }
      .tint(.red)
      .bold()
      .font(.title2)

      Text("End")
    }
  }
}

#Preview {
  PreviewEnvironment {
    ActiveWorkoutControlsView()
  }
}
