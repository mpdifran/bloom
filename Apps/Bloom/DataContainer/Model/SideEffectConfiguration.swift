//
//  SideEffectConfiguration.swift
//  DataContainer
//
//  Created by Assistant on 2025-08-09.
//

import Foundation
import HealthKit

// MARK: - Base Protocol
public protocol SideEffectConfiguration: Codable, Sendable {
  static var type: SideEffectType { get }
}

// MARK: - Log Food Configuration
public struct LogFoodSideEffectConfig: SideEffectConfiguration {
  public static let type = SideEffectType.logFood
  
  public let foodItemID: String
  public let foodItemName: String
  public let servingSize: Double
  public let meal: FoodItemLog.Meal
  
  public init(foodItemID: String, foodItemName: String, servingSize: Double, meal: FoodItemLog.Meal) {
    self.foodItemID = foodItemID
    self.foodItemName = foodItemName
    self.servingSize = servingSize
    self.meal = meal
  }
}

// MARK: - Log Water Configuration
public struct LogWaterSideEffectConfig: SideEffectConfiguration {
  public static let type = SideEffectType.logWater
  
  public let amount: Double
  public let unitString: String
  
  public init(amount: Double, unit: HKUnit) {
    self.amount = amount
    self.unitString = unit.unitString
  }
}

// MARK: - Side Effect Execution Result
public struct SideEffectExecutionResult: Codable, Sendable {
  public let sideEffectID: String
  public let type: SideEffectType
  public let createdRecordID: String?
  public let success: Bool
  
  public init(sideEffectID: String, type: SideEffectType, createdRecordID: String?, success: Bool) {
    self.sideEffectID = sideEffectID
    self.type = type
    self.createdRecordID = createdRecordID
    self.success = success
  }
}