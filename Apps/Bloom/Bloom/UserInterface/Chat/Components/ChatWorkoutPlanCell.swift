//
//  ChatWorkoutPlanCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-29.
//

import SwiftUI
import BloomModel
import DataContainer
import TelemetryDeck

struct ChatWorkoutPlanCell: View {
  let chatMessageID: String
  let workoutPlan: SocketMessage.WorkoutPlan

  init(
    chatMessageID: String,
    workoutPlan: SocketMessage.WorkoutPlan,
    hasPerformedAction: Bool
  ) {
    self.chatMessageID = chatMessageID
    self.workoutPlan = workoutPlan
    self._hasSavedWorkout = State(initialValue: hasPerformedAction)
  }

  @State private var saveComplete = false
  @State private var hasSavedWorkout = false
  @State private var showingDetails = false

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        HStack(alignment: .top) {
          WorkoutPlanIconView(
            workoutType: workoutPlan.representativeAppleWorkoutType,
            dimension: 50
          )

          VStack(alignment: .leading) {
            Text(workoutPlan.title)
              .font(.title3)
              .bold()
              .fontDesign(.rounded)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(3)
          }
          .multilineTextAlignment(.leading)

          Spacer(minLength: 0)

          DisclosureIndicator()
        }

        Text(workoutPlan.summary)
          .font(.subheadline)
          .fixedSize(horizontal: false, vertical: true)
          .multilineTextAlignment(.leading)

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
      .chatCardContainer()
      .onTapGesture {
        showingDetails = true
      }
    }
    .padding(.horizontal)
    .tint(.green)
    .sheet(isPresented: $showingDetails) {
      NavigationStack {
        ChatWorkoutPlanDetailsView(
          chatMessageID: chatMessageID,
          workoutPlan: workoutPlan,
          hasSavedWorkout: $hasSavedWorkout
        )
      }
    }
  }
}

extension ChatWorkoutPlanCell {

  var subtitle: String {
    "\(workoutPlan.durationDescription) • \(workoutPlan.equipmentDescription)"
  }

  func save() throws {
    try modelContext.savingTransaction {
      var sets = [WorkoutSet]()

      for (setIndex, set) in workoutPlan.sets.enumerated() {
        var exercises = [WorkoutExercise]()
        for (exerciseIndex, exercise) in set.exercises.enumerated() {
          exercises.append(
            WorkoutExercise(
              id: UUID().uuidString,
              index: exerciseIndex,
              title: exercise.title,
              summary: exercise.instructions,
              numberOfReps: exercise.numberOfReps,
              distance: exercise.distance,
              distanceUnit: exercise.distanceUnit?.swiftDataUnit,
              duration: exercise.duration,
              kind: .exercise
            )
          )
        }

        let set = WorkoutSet(
          id: UUID().uuidString,
          index: setIndex,
          title: set.title,
          focus: set.focus,
          numberOfSets: set.numberOfSets,
          format: set.format.hkFormat,
          duration: set.duration,
          restBetweenExercises: set.restBetweenExercises,
          appleWorkoutType: set.appleWorkoutType.hkWorkoutType
        )
        set.exercises = exercises
        sets.append(set)
      }

      let workoutPlanModel = WorkoutPlan(
        id: UUID().uuidString,
        title: workoutPlan.title,
        summary: workoutPlan.summary,
        creationDate: .now,
        requiredEquipment: workoutPlan.requiredEquipment.map({ $0.hkEquipment })
      )
      workoutPlanModel.sets = sets

      modelContext.insert(workoutPlanModel)
    }

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

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ChatWorkoutPlanCell(
        chatMessageID: "1234",
        workoutPlan: .Preview.deadlifts,
        hasPerformedAction: false
      )
      ChatWorkoutPlanCell(
        chatMessageID: "1234",
        workoutPlan: .Preview.deadlifts,
        hasPerformedAction: false
      )
    }
  }
}
