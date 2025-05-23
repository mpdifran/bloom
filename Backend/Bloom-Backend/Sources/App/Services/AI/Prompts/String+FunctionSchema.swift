//
//  String+FunctionSchema.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-23.
//

import Vapor
import BloomModel

extension String {
  enum FunctionSchema { }
}

extension String.FunctionSchema {

  static let logFood: String = """
    Log Food: {
      "name": String, // Required. The name you would give the food. Capitalize using title case.
      "meal": Meal, // Required. The meal you think this food is for. You can use the current time, as well as the type of food to determine this.
      "foodItems": [FoodItem] // Required. A list of individual food items detected.
    }
    
    Meal: An enum with the following types: \(SocketMessage.DetectedFood.Meal.stringCaseList())
    
    FoodItem: {
      "name": String,           // Required. The name of this food item. Capitalize using title case.
      "servingName": String,    // Required. A name for a single serving of the food item. It should not contain the name of the item itself, and should contain a number. It should include the mass of the serving in brackets. Example: "6 crackers (20 g)"
      "servingCount": Double,   // Required. The number of servings of the food item you detect
      "calories": Double,       // Required. The amount of calories, measured in kcal
      "fat": Double,            // Optional. The amount of fat, measured in g
      "protein": Double,        // Optional. The amount of protein, measured in g
      "carbohydrates": Double,  // Optional. The amount of carbohydrates, measured in g
      "saturatedFat": Double,   // Optional. The amount of saturated fat, measured in g
      "transFat": Double,       // Optional. The amount of trans fat, measured in g
      "polyunsaturatedFat": Double, // Optional. The amount of polyunsaturated fat, measured in g
      "monounsaturatedFat": Double, // Optional. The amount of monounsaturated fat, measured in g
      "fiber": Double,          // Optional. The amount of fiber, measured in g
      "sugar": Double,          // Optional. The amount of sugar, measured in g
      "cholesterol": Double,    // Optional. The amount of cholesterol, measured in mg
      "sodium": Double,         // Optional. The amount of sodium, measured in mg
      "calcium": Double,        // Optional. The amount of calcium, measured in mg
      "iron": Double,           // Optional. The amount of iron, measured in mg
      "potassium": Double,      // Optional. The amount of potassium, measured in mg
      "magnesium": Double,      // Optional. The amount of magnesium, measured in mg
      "zinc": Double,           // Optional. The amount of zinc, measured in mg
      "vitaminA": Double,       // Optional. The amount of vitamin A, measured in mcg
      "vitaminB6": Double,      // Optional. The amount of vitamin B6, measured in mg
      "vitaminB12": Double,     // Optional. The amount of vitamin B12, measured in mcg
      "vitaminC": Double,       // Optional. The amount of vitamin C, measured in mg
      "vitaminD": Double,       // Optional. The amount of vitamin D, measured in mcg
      "vitaminE": Double,       // Optional. The amount of vitamin E, measured in mg
    }
    """
}
