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
    let data = try encoder.encode(responseSchema.schema)

    guard
      let schema = String(data: data, encoding: .utf8)
    else { throw Abort(.internalServerError, reason: "Could not create JSON Schema.") }

    return "Your response must be in JSON, and use the following JSON format exactly. Note: you do not need to escape single quotes.\n\n\(schema)"
  }

  static let suggestGoals: String = """
  Give me goals to improve my health and to hit my target health goal. Goals should be actionable and things users can do to move a metric. For existing goals, try gently tweaking the value in the right direction. Do not recommend something over scientifically recommended ranges.
  
  Please take into consideration any existing goals set and the target. Do not limit recommendations to already defined goals, but if you adjust any, keep these in mind to ensure recommended changes are doable.
  
  Don't overwhelm the user with too many goals.
  """
}
