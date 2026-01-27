//
//  WorkoutSettingsView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-26.
//

import SwiftUI
import SFSafeSymbols

struct WorkoutSettingsView: View {
  @ObservedObject private var pinnedWorkoutsManager = PinnedWorkoutsManager.shared
  @State private var presentedSheet: AnyView?

  var body: some View {
    NavigationStack {
      List {
        ForEach(pinnedVariants) { variant in
          WorkoutVariantCell(variant: variant, isPinned: true)
            .onTapGesture {
              withAnimation {
                pinnedWorkoutsManager.unpin(variant)
              }
            }
        }
        .onMove { source, destination in
          pinnedWorkoutsManager.move(fromOffsets: source, toOffset: destination)
        }

        addPinnedWorkoutCell
      }
      .listStyle(.carousel)
      .navigationTitle("Settings")
    }
    .sheet($presentedSheet)
  }
}

// MARK: - Views

private extension WorkoutSettingsView {

  var pinnedVariants: [WorkoutVariant] {
    pinnedWorkoutsManager.pinnedWorkoutIds
      .compactMap { WorkoutVariant.from(id: $0) }
  }

  var addPinnedWorkoutCell: some View {
    HStack(spacing: 10) {
      WorkoutIcon(
        symbol: .plus,
        scale: .small
      )
      .bold()

      Text("Add Starred Workout")
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
    }
    .padding(.vertical, 10)
    .selectable()
    .onTapGesture {
      presentedSheet = WorkoutPickerView { variant in
        pinnedWorkoutsManager.pin(variant)
        presentedSheet = nil
      }.asAny
    }
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutSettingsView()
  }
}
