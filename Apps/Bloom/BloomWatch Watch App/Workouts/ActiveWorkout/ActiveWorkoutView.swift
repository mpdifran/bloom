//
//  ActiveWorkoutView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI
import CoreHealth
import AppUI
import WatchKit

private extension ActiveWorkoutView {
  enum Tab {
    case metrics
    case nowPlaying
  }
}

struct ActiveWorkoutView: View {
  @EnvironmentObject var workoutManager: WorkoutManager
  @Environment(\.isLuminanceReduced) var isLuminanceReduced

  @State private var selection: Tab = .metrics
  @State private var presentedSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      TabView(selection: $selection) {
        ActiveWorkoutMetricsView()
          .tag(Tab.metrics)
        NowPlayingView()
          .removeCancellationToolbarItem()
          .tag(Tab.nowPlaying)
      }
      .tabViewStyle(.verticalPage)
    }
    .background {
      Rectangle()
        .fill(.black)
        .ignoresSafeArea()
    }
    .onChange(of: isLuminanceReduced) {
      displayMetricsView()
    }
    .onChange(of: workoutManager.sessionState) { _, newValue in
      if newValue == .ended && !workoutManager.isSwitchingWorkout {
        if workoutManager.workout == nil {
          // Workout was discarded (too short) — skip summary
          dismiss()
        } else if workoutManager.isMultiWorkoutSession {
          presentedSheet = MultiWorkoutSummaryView(
            segments: workoutManager.completedSegments,
            onDismiss: { dismiss() }
          ).asAny
        } else {
          presentedSheet = ActiveWorkoutSummaryView {
            dismiss()
          }.asAny
        }
      } else if newValue == .running || newValue == .paused {
        displayMetricsView()
      }
    }
    .sheet($presentedSheet)
  }
}

private extension ActiveWorkoutView {

  var title: String {
    workoutManager.session?.workoutConfiguration.activityType.name ?? "Workout"
  }

  func displayMetricsView() {
    withAnimation {
      selection = .metrics
    }
  }
}

#Preview {
  PreviewEnvironment {
    ActiveWorkoutView()
  }
}
