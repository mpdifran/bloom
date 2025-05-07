//
//  BloomWatchApp.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2025-05-05.
//

import SwiftUI
import CoreHealth
import AppUI

@main
struct BloomWatch_Watch_AppApp: App {
  @WKApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  @State private var presentedFullScreen: AnyView?

  @ObservedObject private var workoutManager = WorkoutManager.shared

  @Environment(\.dismiss) private var dismiss

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        LaunchWorkoutListView()
      }
      .onAppear {
        if workoutManager.sessionState.isActive && presentedFullScreen == nil {
          presentedFullScreen = ActiveWorkoutView().asAny
        }
      }
      .onChange(of: workoutManager.sessionState) { (_, newValue) in
        if newValue.isActive && presentedFullScreen == nil {
          presentedFullScreen = ActiveWorkoutView().asAny
        }
      }
      .fullScreenCover($presentedFullScreen)
      .environmentObject(workoutManager)
    }
  }
}
