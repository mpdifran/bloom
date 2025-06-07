//
//  ChatCellModel.swift
//  Bloom
//
//  Created by Assistant on 2025-01-29.
//

import Foundation
import DataContainer
import HealthKit
import BloomModel
import DifferenceKit

// Processed rich content data to avoid async loading in UI
enum ProcessedRichContent: Equatable {
  case goals([ProposedGoal])
  case detectedFood(name: String, meal: FoodItemLog.Meal, servings: [FoodItemServingAmount])
  case logWater(HKQuantity)
  case logBowelMovement(bristolStoolType: Int, duration: BowelMovement.Duration)
  case logWeight(HKQuantity)
  case logPeriod(HKCategoryValueMenstrualFlow)
  case logBloodPressure(systolic: Double, diastolic: Double)
  case createReminder(reminderID: String)
  case workoutPlan(SocketMessage.WorkoutPlan)
  case unknown
}

enum ChatCellType: Equatable {
  case message(ChatMessageDTO)
  case inProgress(ChatController.InProgressMessage)
  case richContent(chatMessageID: String, content: ProcessedRichContent, hasPerformedAction: Bool, dbID: String?)
  case typingIndicator
  case statusText(String)
  case prompts
}

struct ChatCellModel: Identifiable, Equatable {
  let id: String
  let contentType: ChatCellType
}

// Make ChatCellModel conform to Differentiable for efficient updates
extension ChatCellModel: Differentiable {
  var differenceIdentifier: String {
    return id
  }
  
  func isContentEqual(to source: ChatCellModel) -> Bool {
    // For in-progress messages, we need to check if the message content changed
    switch (self.contentType, source.contentType) {
    case (.inProgress(let selfMessage), .inProgress(let sourceMessage)):
      // Check if the actual message content changed
      return selfMessage.message == sourceMessage.message && selfMessage.data == sourceMessage.data
    default:
      // For all other cases, use standard equality
      return self == source
    }
  }
}
