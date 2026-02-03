//
//  WatchFoodLogData.swift
//  BloomFoundation
//
//  Created by Claude on 2026-01-30.
//

import Foundation

// MARK: - Quick Food Log (From Frequent Foods)

/// Message sent from watch to iOS to log a food item
public struct WatchFoodLogMessage: Codable, Sendable {
  public static let messageType = "foodLog"

  public let type: String
  public let foodItemID: String
  public let meal: String
  public let numberOfServings: Double
  public let date: Date

  public init(
    foodItemID: String,
    meal: String,
    numberOfServings: Double,
    date: Date = Date()
  ) {
    self.type = Self.messageType
    self.foodItemID = foodItemID
    self.meal = meal
    self.numberOfServings = numberOfServings
    self.date = date
  }
}

/// Response from iOS after logging a food item
public struct WatchFoodLogResponse: Codable, Sendable {
  public let success: Bool
  public let logID: String?
  public let errorMessage: String?

  public init(success: Bool, logID: String? = nil, errorMessage: String? = nil) {
    self.success = success
    self.logID = logID
    self.errorMessage = errorMessage
  }
}

// MARK: - Voice Food Log (Bloom Plus)

/// Message sent from watch to iOS for voice-based food logging
public struct WatchVoiceFoodLogMessage: Codable, Sendable {
  public static let messageType = "voiceFoodLog"

  public let type: String
  public let transcribedText: String
  public let meal: String
  public let date: Date

  public init(
    transcribedText: String,
    meal: String,
    date: Date = Date()
  ) {
    self.type = Self.messageType
    self.transcribedText = transcribedText
    self.meal = meal
    self.date = date
  }
}

/// Response from iOS after initiating voice food log processing
public struct WatchVoiceFoodLogResponse: Codable, Sendable {
  public let success: Bool
  public let processingIdentifier: String?
  public let errorMessage: String?

  public init(success: Bool, processingIdentifier: String? = nil, errorMessage: String? = nil) {
    self.success = success
    self.processingIdentifier = processingIdentifier
    self.errorMessage = errorMessage
  }
}

// MARK: - Meal Log (Saved Meals)

/// Message sent from watch to iOS to log a saved meal
public struct WatchMealLogMessage: Codable, Sendable {
  public static let messageType = "mealLog"

  public let type: String
  public let mealRecordID: String
  public let meal: String
  public let date: Date

  public init(
    mealRecordID: String,
    meal: String,
    date: Date = Date()
  ) {
    self.type = Self.messageType
    self.mealRecordID = mealRecordID
    self.meal = meal
    self.date = date
  }
}

// MARK: - Pending Food Log Entry (For Offline Queue)

/// Entry stored locally on watch when iOS is unavailable
public struct WatchPendingFoodLogEntry: Codable, Sendable, Identifiable {
  public let id: String
  public let foodItemID: String
  public let meal: String
  public let numberOfServings: Double
  public let date: Date
  public let createdAt: Date

  public init(
    id: String = UUID().uuidString,
    foodItemID: String,
    meal: String,
    numberOfServings: Double,
    date: Date,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.foodItemID = foodItemID
    self.meal = meal
    self.numberOfServings = numberOfServings
    self.date = date
    self.createdAt = createdAt
  }

  public func toMessage() -> WatchFoodLogMessage {
    WatchFoodLogMessage(
      foodItemID: foodItemID,
      meal: meal,
      numberOfServings: numberOfServings,
      date: date
    )
  }
}
