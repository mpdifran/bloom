//
//  ChatWorkoutPlanDetailsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-09.
//

import SwiftUI
import BloomModel
import DataContainer
import TelemetryDeck
import SFSafeSymbols
import BloomUI

struct ChatWorkoutPlanDetailsView: View {
  let chatMessageID: String
  let workoutPlan: SocketMessage.WorkoutPlan
  @Binding var hasSavedWorkout: Bool

  @State private var saveComplete = false

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
      ToolbarItem(placement: .principal) {
        Image(systemSymbol: SFSymbol(rawValue: workoutPlan.representativeAppleWorkoutType.systemImage))
      }
      ToolbarItem(placement: .cancellationAction) {
        DismissButton()
      }
    }
    .shelf {
      AsyncButton {
        try save()
      } label: {
        Text(hasSavedWorkout ? "Workout Saved" : "Save Workout")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .sensoryFeedback(.success, trigger: saveComplete)
      .disabled(hasSavedWorkout)
    }
    .tint(.blue)
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

private extension ChatWorkoutPlanDetailsView {

  var titleSection: some View {
    HStack(spacing: 20) {
      WorkoutPlanIconView(workoutTypes: workoutPlan.displayWorkoutTypes)

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

      ForEach(Array(workoutPlan.sets.enumerated()), id: \.offset) { index, set in
        ChatWorkoutSetDetailsDisclosureCell(set: set)
      }
    }
  }

  func save() throws {
    try workoutPlan.saveToSwiftData(modelContext: modelContext)

    TelemetryDeck.signal("Save Workout")

    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: true)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
    hasSavedWorkout = true

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }
}

struct ChatWorkoutSetDetailsDisclosureCell: View {
  let set: SocketMessage.WorkoutSet

  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      content
    } label: {
      label
    }
    .disclosureGroupStyle(ChatWorkoutSetDetailsDisclosureGroupStyle())
  }
}

private extension ChatWorkoutSetDetailsDisclosureCell {

  var label: some View {
    HStack {
      Image(systemSymbol: SFSymbol(rawValue: set.appleWorkoutType.hkWorkoutType.systemImage))
        .foregroundStyle(.blue)
        .font(.largeTitle)
        .frame(width: 60)

      VStack(alignment: .leading) {
        Text(set.title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)

        Text(verbatim: "\(set.format.name) • \(set.setsDescription)")
          .font(.subheadline)
          .fixedSize(horizontal: false, vertical: true)

        Text(set.focus)
          .lineLimit(3)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .lineLimit(2)

      Spacer()
    }
  }

  var content: some View {
    VStack(alignment: .leading) {
      ForEach(Array(set.exercises.enumerated()), id: \.offset) { index, exercise in
        Divider()

        ChatWorkoutExerciseDetailsCell(exercise: exercise)

        if set.restBetweenExercises > 0 {
          Divider()

          ChatWorkoutExerciseDetailsRestCell(restDuration: set.restBetweenExercises)
        }
      }
    }
  }
}

private struct ChatWorkoutSetDetailsDisclosureGroupStyle: DisclosureGroupStyle {
  @State private var selectionToggle = false

  func makeBody(configuration: Configuration) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        configuration.label
        Spacer()
        Image(systemSymbol: .chevronDown)
          .fontDesign(.rounded)
          .rotationEffect(.degrees(configuration.isExpanded ? -180 : 0))
      }
      .selectable()
      .onTapGesture {
        withAnimation {
          configuration.isExpanded.toggle()
        }
        selectionToggle.toggle()
      }

      if configuration.isExpanded {
        configuration.content
      }
    }
    .clipped()
    .animation(.easeInOut, value: configuration.isExpanded)
    .cardContainer()
    .sensoryFeedback(.selection, trigger: selectionToggle)
  }
}

struct ChatWorkoutExerciseDetailsCell: View {
  let exercise: SocketMessage.WorkoutExercise

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(exercise.title)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)

        Spacer()

        Text(exercise.measurementDescription)
          .lineLimit(1)
          .fixedSize(horizontal: false, vertical: true)
      }

      Text(exercise.instructions)
        .lineLimit(3)
        .foregroundStyle(.secondary)
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }
    .font(.headline)
    .bold()
    .fontDesign(.rounded)
  }
}

struct ChatWorkoutExerciseDetailsRestCell: View {
  let restDuration: TimeInterval

  var body: some View {
    HStack {
      Text("Rest")
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()

      Text(DateFormatter.timeIntervalHourMinuteSecondShort.string(from: DateComponents(second: Int(restDuration))) ?? "")
        .lineLimit(1)
        .fixedSize(horizontal: false, vertical: true)
    }
    .font(.headline)
    .bold()
    .fontDesign(.rounded)
    .foregroundStyle(.secondary)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ChatWorkoutPlanDetailsView(
        chatMessageID: "1234",
        workoutPlan: .Preview.deadlifts,
        hasSavedWorkout: .constant(false)
      )
    }
  }
}
