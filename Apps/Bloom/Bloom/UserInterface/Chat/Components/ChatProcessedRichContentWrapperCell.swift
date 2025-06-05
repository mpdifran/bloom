//
//  ChatProcessedRichContentWrapperCell.swift
//  Bloom
//
//  Created by Assistant on 2025-06-02.
//

import SwiftUI
import AppUI
import HealthKit
import BloomModel
import DataContainer

struct ChatProcessedRichContentWrapperCell: View {
  let chatMessageID: String
  let content: ProcessedRichContent
  let hasPerformedAction: Bool
  let dbID: String?

  var body: some View {
    Group {
      switch content {
      case .goals(let goals):
        ChatGoalsCell(
          chatMessageID: chatMessageID,
          goals: goals,
          hasPerformedAction: hasPerformedAction
        )
        
      case .detectedFood(let name, let meal, let servings):
        ChatDetectedFoodCell(
          chatMessageID: chatMessageID,
          name: name,
          meal: meal,
          servings: servings,
          hasPerformedAction: hasPerformedAction,
          dbID: dbID
        )
        
      case .logWater(let waterQuantity):
        ChatLogWaterCell(
          chatMessageID: chatMessageID,
          waterQuantity: waterQuantity,
          hasPerformedAction: hasPerformedAction,
          dbID: dbID
        )
        
      case .logBowelMovement(let bristolStoolType, let duration):
        ChatLogBowelMovementCell(
          chatMessageID: chatMessageID,
          bristolStoolType: bristolStoolType,
          duration: duration,
          hasPerformedAction: hasPerformedAction,
          dbID: dbID
        )
        
      case .logWeight(let weightQuantity):
        ChatLogWeightCell(
          chatMessageID: chatMessageID,
          weightQuantity: weightQuantity,
          hasPerformedAction: hasPerformedAction,
          dbID: dbID
        )
        
      case .logPeriod(let flowType):
        ChatLogPeriodCell(
          chatMessageID: chatMessageID,
          flow: flowType,
          hasPerformedAction: hasPerformedAction,
          dbID: dbID
        )
        
      case .logBloodPressure(let systolic, let diastolic):
        ChatLogBloodPressureCell(
          chatMessageID: chatMessageID,
          systolic: systolic,
          diastolic: diastolic,
          hasPerformedAction: hasPerformedAction,
          dbID: dbID
        )
        
      case .workoutPlan(let workoutPlan):
        ChatWorkoutPlanCell(
          chatMessageID: chatMessageID,
          workoutPlan: workoutPlan,
          hasPerformedAction: hasPerformedAction
        )
        
      case .createReminder(let createReminder):
        ReminderCell(
          reminder: createReminder.asReminderDTO(),
          occurrence: createReminder.occurrences.first?.asReminderOccurrenceDTO(),
          isCompleted: false
        )
        .horizontalAlignment(.leading)
        .padding(.leading)
      case .unknown:
        ChatUnknownContentCell()
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatProcessedRichContentWrapperCell(
          chatMessageID: "123",
          content: .logPeriod(.medium),
          hasPerformedAction: false,
          dbID: "1234"
        )
        ChatBubbleCell(
          message: "Here's some processed rich content",
          isDirect: false,
          isCurrentUser: false,
          showTail: true
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
