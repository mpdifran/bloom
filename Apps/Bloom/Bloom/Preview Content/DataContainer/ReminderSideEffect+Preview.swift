import Foundation
import DataContainer
import HealthKit

extension ReminderSideEffect {
  enum Preview {
    static let logVitamins = ReminderSideEffect.logFood(
      foodItem: FoodItemRecord.Preview.vitaminD,
      servingSize: 1,
      meal: .breakfast
    )
    
    static let logWater16oz = ReminderSideEffect.logWater(
      amount: 16,
      unit: .fluidOunceUS()
    )
    
    static let logWater32oz = ReminderSideEffect.logWater(
      amount: 32,
      unit: .fluidOunceUS()
    )
    
    static let logProteinShake = ReminderSideEffect.logFood(
      foodItem: FoodItemRecord.Preview.proteinPowder,
      servingSize: 1,
      meal: .snack
    )
  }
}