//
//  String+Prompts.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-23.
//

import Foundation
import Vapor
import OpenAIKit

extension String {
  enum Prompt { }
}

extension String.Prompt {

  static let packagingParse: String = """
  Read the packaging in the photo and determine the brand, product name, and optional flavour. Each string should have
  the first letter of each word capitalized. If the text is in French, or Spanish, convert it to English, or prefer English text.
  """

  static let nutritionLabelParse: String = """
  Read the nutrition label in the photo, and determine the nutrients in the food item. If the nutrition label is in French, or Spanish, translate it to English.
  """

  static let estimateCalories: String = """
  You are a nutritionist, and your job is to estimate all the nutrients in a photo of food. Make sure to only estimate 
  edible items.
  """

  static let estimateCaloriesByText: String = """
  You are a nutritionist, and your job is to estimate all the nutrients based on a description of the food. Make sure to 
  only estimate edible items. If it's unclear how many servings are included for a food item, assume 1 serving. When 
  deciding the size of a serving, try and make it the smallest reasonable unit for the food. ex: 1 chicken finger, or 
  250 mL of milk. Use 'servingCount' to indicate the amount of each food item. ex: If the input is '4 chicken strips', 
  'servingName' should be '1 chicken strip', and 'servingCount' should be '4'.
  """

  static func jsonSchemaDefinition(_ responseSchema: ResponseSchema) throws -> String {
    let encoder = JSONEncoder()
    let data = try encoder.encode(responseSchema)

    guard
      let schema = String(data: data, encoding: .utf8)
    else { throw Abort(.internalServerError, reason: "Could not create JSON Schema.") }

    return "Your response must be in JSON, and use the following JSON Schema format. Note: you do not need to escape single quotes.\n\n\(schema)"
  }

  static let suggestGoals: String = """
  Perform the following steps:
  
  1) Look at the user's health data and analyze the trends.
  2) Identify the areas of the user's health that are the most important to focus on.
  3) Analyze the user's current goals, determine how often they met them over the last 7 days, and decide if they align with the health focus areas.
  4) Suggest new goals, or edit existing goals to align better with the user's health focus areas. If the user has no goals, feel free to give them 1 to 2 goals.
  5) Make sure the goals are set gently. Don't set the value too high if the user is new to the metric.
  6) Make sure there's at least one goal.
  7) Only if your suggestion doesn't fit into a goal, set a reminder. Strongly prefer setting a goal over a reminder.
    
  Notes:
  Keep responses short, positive, and engaging.
  Don't overwhelm the user with too many goals or reminders; stay focused.
  Always return at least one goal.
  """
}
