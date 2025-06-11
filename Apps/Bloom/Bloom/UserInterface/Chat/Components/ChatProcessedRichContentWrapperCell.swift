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
  let showReportButton: Bool
  let responseID: String?
  let requestID: String?
  
  @State private var showReportSheet = false

  var body: some View {
    VStack(alignment: .leading) {
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
        
      case .createReminder(let reminderID):
        ChatDatabaseReminderCell(reminderID: reminderID)
      case .deleteReminder(let reminderID):
        ChatDatabaseReminderCell(reminderID: reminderID)
      case .createUserFacts(let createUserFacts):
        ChatCreateUserFactsCell(
          chatMessageID: chatMessageID,
          userFacts: createUserFacts
        )
      case .deleteUserFacts(let deleteUserFacts):
        ChatDeleteUserFactsCell(
          chatMessageID: chatMessageID,
          deleteUserFacts: deleteUserFacts,
          hasPerformedAction: hasPerformedAction
        )
      case .unknown:
        ChatUnknownContentCell()
        }
      }
      
      if showReportButton, 
         responseID != nil,
         requestID != nil {
        Button("Report a Problem") {
          showReportSheet = true
        }
        .bold()
        .font(.caption)
        .padding(.horizontal)
        .padding(.horizontal)
      }
    }
    .sheet(isPresented: $showReportSheet) {
      if let responseID = responseID,
         let requestID = requestID {
        ChatReportReviewView(
          responseID: responseID,
          requestID: requestID
        )
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
          dbID: "1234",
          showReportButton: false,
          responseID: nil,
          requestID: nil
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
