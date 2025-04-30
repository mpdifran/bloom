//
//  WorkoutTemplateDetailsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import SwiftUI
import DataContainer
import AppUI
import SFSafeSymbols

struct WorkoutTemplateDetailsView: View {
  let workoutTemplate: WorkoutTemplate

  @State private var presentedSheet: AnyView?

  var body: some View {
    BloomScrollView {
      titleSection
      equipmentSection
      stepsSection
    }
    .navigationTitle(workoutTemplate.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Start") {
          presentedSheet = WorkoutInstanceView(workoutTemplate: workoutTemplate).asAny
        }
        .buttonStyle(.secondary)
        .tint(.green)
      }
    }
    .sheet($presentedSheet)
  }
}

private extension WorkoutTemplateDetailsView {

  var titleSection: some View {
    HStack(spacing: 20) {
      WorkoutTemplateIconView(workoutType: workoutTemplate.appleWorkoutType, dimension: 90)

      VStack(alignment: .leading) {
        Text(workoutTemplate.stepsDescription)
          .font(.title2)
          .bold()
          .fontDesign(.rounded)

        Text(workoutTemplate.durationDescription)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
  }

  var equipmentSection: some View {
    VStack {
      SectionTitleView("Equipment")
        .padding(.horizontal)

      VStack(alignment: .leading) {
        if workoutTemplate.equipment.isEmpty {
          Text("No equipment required.")
            .foregroundStyle(.secondary)
        } else {
          Text(workoutTemplate.equipmentDescription)
            .bold()
            .fontDesign(.rounded)
        }
      }
      .horizontalAlignment(.leading)
      .cardContainer()
    }
  }

  var stepsSection: some View {
    VStack {
      SectionTitleView("Exercises")
        .padding(.horizontal)

      ForEach(workoutTemplate.steps ?? []) { step in
        WorkoutStepDetailsCell(
          rootActivityType: workoutTemplate.appleWorkoutType,
          step: step
        )
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      WorkoutTemplateDetailsView(workoutTemplate: .Preview.deadlifts)
    }
  }
}
