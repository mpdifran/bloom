//
//  WorkoutTemplateDetailsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import SwiftUI
import DataContainer

struct WorkoutTemplateDetailsView: View {
  let workoutTemplate: WorkoutTemplate

  var body: some View {
    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
  }
}

private extension WorkoutTemplateDetailsView {

}

#Preview {
  PreviewEnvironment {
    WorkoutTemplateDetailsView(workoutTemplate: .Preview.deadlifts)
  }
}
