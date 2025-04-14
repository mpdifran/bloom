//
//  ChatRichContentWrapperCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-13.
//

import SwiftUI
import AppUI
import BloomModel
import DataContainer

struct ChatRichContentWrapperCell: View {
  let chatMessageID: String
  let data: Data
  let hasPerformedAction: Bool

  @State private var isLoading = true
  @State private var goals: [ProposedGoal]?

  private let modelActor = HabitModelActor.standard()

  var body: some View {
    Group {
      if isLoading {
        HStack {
          HStack {
            Spacer()
            ProgressView()
              .progressViewStyle(.circular)
              .padding()
            Spacer()
          }
          .cardContainer()
          .padding(.leading)

          Spacer(minLength: 60)
        }
      } else {
        if let goals {
          ChatGoalsCell(
            chatMessageID: chatMessageID,
            goals: goals,
            hasPerformedAction: hasPerformedAction
          )
        }
      }
    }
    .animation(.easeInOut, value: isLoading)
    .task {
      await loadContent()
    }
  }
}

private extension ChatRichContentWrapperCell {

  func loadContent() async {
    if let healthGoals = try? JSONDecoder.bloomModel.decode([SocketMessage.HealthMetricGoal].self, from: data) {
      var proposedGoals = [ProposedGoal]()
      for healthGoal in healthGoals {
        let habit = try? await modelActor.fetchActiveHabits(for: healthGoal.metric.targetMetric).first

        let proposedGoal = ProposedGoal(
          habitID: habit?.id,
          targetMetric: healthGoal.metric.targetMetric,
          value: healthGoal.value,
          suggestedValue: healthGoal.value,
          previousValue: habit?.value,
          unitString: healthGoal.unit.hkUnit.unitString,
          vitalKind: nil,
          context: "",
          hasUserEdited: habit?.isUserEdited == true
        )
        proposedGoals.append(proposedGoal)
      }
      if proposedGoals.isNotEmpty {
        self.goals = proposedGoals
      }
    }
    self.isLoading = false
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatBubbleCell(
          message: "Here's some rich content",
          isDirect: false,
          isCurrentUser: false,
          showTail: true
        )
        ChatRichContentWrapperCell(
          chatMessageID: "123",
          data: Data(),
          hasPerformedAction: false
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
