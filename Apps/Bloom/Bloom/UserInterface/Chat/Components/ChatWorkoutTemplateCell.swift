//
//  ChatWorkoutTemplateCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-29.
//

import SwiftUI
import BloomModel
import DataContainer
import TelemetryDeck

struct ChatWorkoutTemplateCell: View {
  let chatMessageID: String
  let workoutTemplate: SocketMessage.WorkoutTemplate

  init(
    chatMessageID: String,
    workoutTemplate: SocketMessage.WorkoutTemplate,
    hasPerformedAction: Bool
  ) {
    self.chatMessageID = chatMessageID
    self.workoutTemplate = workoutTemplate
    self._hasSavedWorkout = State(initialValue: hasPerformedAction)
  }

  @State private var saveComplete = false
  @State private var hasSavedWorkout = false

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        HStack {
          Text(workoutTemplate.title)
            .font(.title3)
            .bold()
            .fontDesign(.rounded)
            .multilineTextAlignment(.leading)
            .lineLimit(3)

          Spacer()

          WorkoutTemplateIconView(
            workoutType: workoutTemplate.appleWorkoutType.hkWorkoutType,
            dimension: 40
          )
        }

        ForEach(workoutTemplate.steps, id: \.self) { step in
          Divider()

          VStack(alignment: .leading) {
            Text(step.title)
              .font(.body)
              .bold()
              .fontDesign(.rounded)

            Text(step.parameterDescription)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        AsyncButton {
          try save()
        } label: {
          Text("Save Workout")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .sensoryFeedback(.success, trigger: saveComplete)
        .disabled(hasSavedWorkout)
        .padding(.top)
      }
      .cardContainer()

      Spacer(minLength: 60)
    }
    .padding(.horizontal)
    .tint(.green)
  }
}

extension ChatWorkoutTemplateCell {

  func save() throws {
    try modelContext.savingTransaction {
      let steps = workoutTemplate.steps.map { step in
        WorkoutStep(
          id: UUID().uuidString,
          title: step.title,
          numberOfReps: step.numberOfReps,
          distance: step.distance,
          distanceUnit: step.distanceUnit?.swiftDataUnit,
          duration: step.duration ?? 0,
          overrideAppleWorkoutType: step.overrideAppleWorkoutType?.hkWorkoutType,
          kind: step.kind.hkKind
        )
      }

      let workoutTemplateModel = WorkoutTemplate(
        id: UUID().uuidString,
        title: workoutTemplate.title,
        creationDate: .now,
        appleWorkoutType: workoutTemplate.appleWorkoutType.hkWorkoutType,
        requiredEquipment: workoutTemplate.requiredEquipment.map({ $0.hkEquipment }),
        steps: steps
      )

      modelContext.insert(workoutTemplateModel)
    }

    TelemetryDeck.signal("Save Workout")

    try modelContext.markChatMessageActionTaken(id: chatMessageID)

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
      ChatWorkoutTemplateCell(
        chatMessageID: "1234",
        workoutTemplate: .Preview.deadlifts,
        hasPerformedAction: false
      )
      ChatWorkoutTemplateCell(
        chatMessageID: "1234",
        workoutTemplate: .Preview.deadlifts,
        hasPerformedAction: false
      )
    }
  }
}
