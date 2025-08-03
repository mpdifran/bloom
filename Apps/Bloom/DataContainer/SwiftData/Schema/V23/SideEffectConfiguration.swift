import Foundation
import HealthKit

// MARK: - Base Protocol
public protocol SideEffectConfiguration: Codable, Sendable {
  static var type: SchemaV23.ReminderSideEffect.SideEffectType { get }
}

// MARK: - Log Food Configuration
public struct LogFoodSideEffectConfig: SideEffectConfiguration {
  public static let type = SchemaV23.ReminderSideEffect.SideEffectType.logFood
  
  public let foodItemID: String
  public let foodItemName: String
  public let servingSize: Double
  public let meal: SchemaV9.FoodItemLog.Meal
  
  public init(foodItemID: String, foodItemName: String, servingSize: Double, meal: SchemaV9.FoodItemLog.Meal) {
    self.foodItemID = foodItemID
    self.foodItemName = foodItemName
    self.servingSize = servingSize
    self.meal = meal
  }
}

// MARK: - Log Water Configuration
public struct LogWaterSideEffectConfig: SideEffectConfiguration {
  public static let type = SchemaV23.ReminderSideEffect.SideEffectType.logWater
  
  public let amount: Double
  public let unitString: String
  
  public init(amount: Double, unit: HKUnit) {
    self.amount = amount
    self.unitString = unit.unitString
  }
}

// MARK: - Helper Extensions
extension SchemaV23.ReminderSideEffect {
  public func decodeConfiguration<T: SideEffectConfiguration>(as type: T.Type) -> T? {
    try? JSONDecoder.dataContainer.decode(type, from: configuration)
  }
  
  public func encodeConfiguration<T: SideEffectConfiguration>(_ config: T) throws {
    configuration = try JSONEncoder.dataContainer.encode(config)
  }
}