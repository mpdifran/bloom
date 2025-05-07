//
//  PreviewEnvironment.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI
import CoreHealth

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
