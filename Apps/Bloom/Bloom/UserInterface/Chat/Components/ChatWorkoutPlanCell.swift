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
      VStack {
        WorkoutPlanIconView(workoutTypes: workoutPlan.displayWorkoutTypes)

        Text(workoutPlan.title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
          .fixedSize(horizontal: false, vertical: true)
          .multilineTextAlignment(.leading)
          .lineLimit(2)

        Text(subtitle)
          .foregroundStyle(.secondary)
          .font(.subheadline)
          .lineLimit(2)

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
      .overlay {
        DisclosureIndicator()
          .zStackAlignment(.topTrailing)
      }
      .chatCardContainer()
      .onTapGesture {
        showingDetails = true
      }
    }
    .padding(.horizontal)
    .tint(.green)
    .fullScreenCover(isPresented: $showingDetails) {
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
