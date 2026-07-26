//
//  CreateWorkoutPlanPreviewView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-02-11.
//

import SwiftUI
import BloomModel
import DataContainer
import TelemetryDeck
import SFSafeSymbols

struct CreateWorkoutPlanPreviewView: View {
  let workoutPlan: SocketMessage.WorkoutPlan
  let onSaveComplete: () -> Void

  @State private var saveComplete = false
  @State private var hasSaved = false

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    BloomScrollView {
      titleSection
      aboutSection
      setsSection
    }
    .navigationTitle(workoutPlan.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        DismissButton()
      }
    }
    .shelf {
      Button {
        save()
      } label: {
        Text(hasSaved ? "Saved" : "Save Workout")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .sensoryFeedback(.success, trigger: saveComplete)
      .disabled(hasSaved)
    }
    .tint(.blue)
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

// MARK: - Views

private extension CreateWorkoutPlanPreviewView {

  var titleSection: some View {
    VStack {
      WorkoutPlanIconView(workoutTypes: workoutPlan.displayWorkoutTypes)

      Group {
        Text(workoutPlan.title)
          .font(.title2)

        Text(workoutPlan.durationDescription)
          .font(.headline)
          .foregroundStyle(.secondary)
      }
      .bold()
      .fontDesign(.rounded)
    }
    .padding(.bottom)
  }

  var aboutSection: some View {
    VStack {
      SectionTitleView("Equipment", includeTopPadding: false)

      VStack(alignment: .leading) {
        Text(workoutPlan.equipmentDescription)

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
      SectionTitleView("Segments")
        .padding(.horizontal)

      ForEach(Array(workoutPlan.sets.enumerated()), id: \.offset) { _, set in
        ChatWorkoutSetDetailsDisclosureCell(set: set)
      }
    }
  }
}

// MARK: - Actions

private extension CreateWorkoutPlanPreviewView {

  func save() {
    do {
      try workoutPlan.saveToSwiftData(modelContext: modelContext)
    } catch {
      return
    }

    TelemetryDeck.signal("Save Generated Workout Plan")

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
    hasSaved = true

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }

    Task {
      try? await Task.sleep(for: .seconds(0.5))
      dismiss()
      onSaveComplete()
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      CreateWorkoutPlanPreviewView(
        workoutPlan: .Preview.deadlifts,
        onSaveComplete: { }
      )
    }
  }
}
