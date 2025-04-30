//
//  WorkoutTemplatesListView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import SwiftUI
import DataContainer
import SwiftData
import HealthKit

struct WorkoutTemplatesListView: View {

  @State private var pushedView: AnyView?

  @Query
  private var workoutTemplates: [WorkoutTemplate]

  var body: some View {
    BloomScrollView {
      ForEach(workoutTemplates) { workoutTemplate in
        WorkoutTemplateCell(workoutTemplate: workoutTemplate)
          .onTapGesture {
            pushedView = WorkoutTemplateDetailsView(workoutTemplate: workoutTemplate).asAny
          }
      }
    }
    .navigationTitle("Workout Templates")
    .navigationDestination($pushedView)
  }
}

#Preview {
  WorkoutTemplatesListView()
}
