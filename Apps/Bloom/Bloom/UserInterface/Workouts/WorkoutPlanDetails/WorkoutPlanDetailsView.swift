//
//  WorkoutPlanDetailsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import SwiftUI
import DataContainer
import AppUI
import SFSafeSymbols

struct WorkoutPlanDetailsView: View {
  let workoutPlan: WorkoutPlan

  @State private var presentedSheet: AnyView?

  var body: some View {
    BloomScrollView {
      titleSection
      aboutSection
      setsSection
    }
    .navigationTitle(workoutPlan.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Image(systemSymbol: SFSymbol(rawValue: workoutPlan.representativeAppleWorkoutType.systemImage))
      }
      ToolbarItem(placement: .primaryAction) {
        Button("Start") {
          presentedSheet = WorkoutInstanceView(workoutPlan: workoutPlan).asAny
        }
        .buttonStyle(.secondary)
        .tint(.green)
      }
    }
    .sheet($presentedSheet)
  }
}

private extension WorkoutPlanDetailsView {

  var titleSection: some View {
    HStack(spacing: 20) {
      WorkoutPlanIconView(workoutType: workoutPlan.representativeAppleWorkoutType, dimension: 90)

      VStack(alignment: .leading) {
        Text(workoutPlan.title)
          .font(.title2)

        Text(workoutPlan.durationDescription)
          .font(.headline)
          .foregroundStyle(.secondary)
      }
      .bold()
      .fontDesign(.rounded)

      Spacer()
    }
    .padding(.bottom)
  }

  var aboutSection: some View {
    VStack {
      SectionTitleView("Equipment", includeTopPadding: false)

      VStack(alignment: .leading) {
        if workoutPlan.equipment.isEmpty {
          Text("No equipment required.")
        } else {
          Text(workoutPlan.equipmentDescription)
        }

        SectionTitleView("Summary")

        Text(workoutPlan.summary)
      }
      .horizontalAlignment(.leading)
      .bold()
      .fontDesign(.rounded)
    }
    .cardContainer()
  }

  var setsSection: some View {
    VStack {
      SectionTitleView("Plan")
        .padding(.horizontal)

      ForEach(workoutPlan.orderedSets) { set in
        WorkoutSetDetailsDisclosureCell(set: set)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      WorkoutPlanDetailsView(workoutPlan: .Preview.deadlifts)
    }
  }
}
