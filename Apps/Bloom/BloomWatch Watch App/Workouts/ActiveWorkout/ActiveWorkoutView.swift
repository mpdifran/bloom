//
//  ActiveWorkoutView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI
import CoreHealth
import AppUI

private extension ActiveWorkoutView {
  enum Tab {
    case controls
    case metrics
  }
}

struct ActiveWorkoutView: View {
  @EnvironmentObject var workoutManager: WorkoutManager
  @Environment(\.isLuminanceReduced) var isLuminanceReduced

  @State private var selection: Tab = .metrics
  @State private var presentedSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    TabView(selection: $selection) {
      ActiveWorkoutControlsView().tag(Tab.controls)
      ActiveWorkoutMetricsView().tag(Tab.metrics)
    }
    .navigationTitle(title)
    .navigationBarBackButtonHidden(true)
    .tabViewStyle(PageTabViewStyle(indexDisplayMode: isLuminanceReduced ? .never : .automatic))
    .onChange(of: isLuminanceReduced) {
      displayMetricsView()
    }
    .onChange(of: workoutManager.sessionState) { _, newValue in
      if newValue == .ended {
        presentedSheet = ActiveWorkoutSummaryView {
          dismiss()
        }.asAny
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
