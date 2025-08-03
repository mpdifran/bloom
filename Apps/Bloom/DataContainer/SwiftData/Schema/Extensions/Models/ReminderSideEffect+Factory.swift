import Foundation
import HealthKit

extension ReminderSideEffect {
  /// Creates a food logging side effect
  public static func logFood(
    foodItem: FoodItemRecord,
    servingSize: Double,
    meal: FoodItemLog.Meal
  ) -> ReminderSideEffect {
    let config = LogFoodSideEffectConfig(
      foodItemID: foodItem.id,
      foodItemName: foodItem.name,
      servingSize: servingSize,
      meal: meal
    )
    
    let configData = (try? JSONEncoder.dataContainer.encode(config)) ?? Data()
    
    let sideEffect = ReminderSideEffect(
      type: .logFood,
      configuration: configData
    )
    // No longer need to set foodItemID separately since it's in the config
    
    return sideEffect
  }
  
  /// Creates a water logging side effect
  public static func logWater(amount: Double, unit: HKUnit) -> ReminderSideEffect {
    let config = LogWaterSideEffectConfig(amount: amount, unit: unit)
    let configData = (try? JSONEncoder.dataContainer.encode(config)) ?? Data()
    
    return ReminderSideEffect(
      type: .logWater,
      configuration: configData
    )
  }
}