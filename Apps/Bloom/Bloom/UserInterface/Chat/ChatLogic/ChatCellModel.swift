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
import SwiftData

struct ChatMessageMetadata: Hashable, Sendable {
  let persistentID: PersistentIdentifier?
  let isCurrentUser: Bool
  let date: Date
  let hasPerformedAction: Bool
  let dbID: String?
  let requestID: String?
  let responseID: String?
  let showReportButton: Bool
}

// Processed rich content data to avoid async loading in UI
enum ProcessedRichContent: Hashable, Sendable {
  case goals([ProposedGoal])
  case detectedFood(name: String, meal: FoodItemLog.Meal, servings: [FoodItemServingAmount], date: Date?)
  case logWater(HKQuantity)
  case logBowelMovement(bristolStoolType: Int, duration: BowelMovement.Duration)
  case logWeight(HKQuantity)
  case logPeriod(HKCategoryValueVaginalBleeding)
  case logBloodPressure(systolic: Double, diastolic: Double)
  case createReminder(reminderID: String)
  case deleteReminder(reminderID: String)
  case createUserFacts(SocketMessage.CreateUserFacts)
  case deleteUserFacts(SocketMessage.DeleteUserFacts)
  case workoutPlan(SocketMessage.WorkoutPlan)
  case unknown
}

enum ChatCellType: Hashable, Sendable {
  case text(id: String, content: String, metadata: ChatMessageMetadata?)
  case image(id: String, imageData: Data, metadata: ChatMessageMetadata?)
  case richContent(id: String, content: ProcessedRichContent, metadata: ChatMessageMetadata?)
  case typingIndicator
  case statusText(String)
  case prompts
}

struct ChatCellModel: Identifiable, Hashable, Sendable {
  let id: String
  let contentType: ChatCellType
}

// Make ChatCellModel conform to Differentiable for efficient updates
extension ChatCellModel: Differentiable {
  var differenceIdentifier: String {
    return id
  }
  
  func isContentEqual(to source: ChatCellModel) -> Bool {
    // For text messages, we need to check if the content changed (for streaming updates)
    switch (self.contentType, source.contentType) {
    case (.text(_, let selfContent, _), .text(_, let sourceContent, _)):
      return selfContent == sourceContent
    default:
      // For all other cases, use standard equality
      return self == source
    }
  }
}
