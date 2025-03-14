//
//  ResponseSchema+Constants.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-03-03.
//

import Foundation
import BloomModel
@preconcurrency import OpenAIKit

// MARK: - Package Scanning

extension ResponseSchema {
  static let packagingParse = ResponseSchema(
    name: "packagingParse",
    schema: Schema.Object(
      properties: [
        "brandName": Schema.Parameter(
          type: .string,
          description: "The brand name of the product."
        ),
        "productName": Schema.Parameter(
          type: .string,
          description: "The name of the product."
        ),
        "flavour": Schema.Parameter(
          type: .optionalString,
          description: "The flavour of the product."
        )
      ]
    )
  )

  static let nutritionLabelParse = ResponseSchema(
    name: "nutritionLabelParse",
    schema: Schema.Object(
      properties: [
        "servingName": Schema.Parameter(
          type: .string,
          description: "The name of one serving of the item, e.g. 1 bottle or 2 brownies"
        ),
        "servingValue": Schema.Parameter(ref: "quantity"),
        "calories": Schema.Parameter(ref: "quantity"),
        "protein": Schema.Parameter(ref: "quantity"),
        "carbohydrate": Schema.Parameter(ref: "quantity"),
        "fat": Schema.Parameter(ref: "quantity"),
        "saturatedFat": Schema.Parameter(ref: "quantity"),
        "transFat": Schema.Parameter(ref: "quantity"),
        "polyunsaturatedFat": Schema.Parameter(ref: "quantity"),
        "monounsaturatedFat": Schema.Parameter(ref: "quantity"),
        "fiber": Schema.Parameter(ref: "quantity"),
        "sugar": Schema.Parameter(ref: "quantity"),
        "cholesterol": Schema.Parameter(ref: "quantity"),
        "sodium": Schema.Parameter(ref: "quantity"),
        "calcium": Schema.Parameter(ref: "quantity"),
        "iron": Schema.Parameter(ref: "quantity"),
        "potassium": Schema.Parameter(ref: "quantity"),
        "magnesium": Schema.Parameter(ref: "quantity"),
        "zinc": Schema.Parameter(ref: "quantity"),
        "vitaminA": Schema.Parameter(ref: "quantity"),
        "vitaminB6": Schema.Parameter(ref: "quantity"),
        "vitaminB12": Schema.Parameter(ref: "quantity"),
        "vitaminC": Schema.Parameter(ref: "quantity"),
        "vitaminD": Schema.Parameter(ref: "quantity"),
        "vitaminE": Schema.Parameter(ref: "quantity")
      ],
      references: [
        "quantity": Schema.Object.quantity
      ]
    )
  )
}

// MARK: - AI Estimate

extension ResponseSchema {
  static let aiEstimate = ResponseSchema(
    name: "aiEstimate",
    schema: Schema.Object(
      properties: [
        "name": Schema.Parameter(
          type: .string,
          description: "A short, concise name to describe the food in the image."
        ),
        "foodItems": Schema.Parameter(
          description: "The individual food items detected in the image. You should have high confidence these food items exist in the photo.",
          arrayOf: .AIEstimate.item
        ),
        "optionalFoodItems": Schema.Parameter(
          description: "Extra individual food items that may be in the photo. This could be things like butter or cooking oil that are difficult to identify from the photo, or an alternate options for food you have a low confidence on. Only add FoodItemServings to this list if they are NOT included in `items` already. You should try and put at least 1-3 items in this list.",
          arrayOf: .AIEstimate.item
        )
      ],
      references: [
        "quantity": Schema.Object.quantity
      ]
    )
  )

  static let textAIEstimate = ResponseSchema(
    name: "aiEstimate",
    schema: Schema.Object(
      properties: [
        "name": Schema.Parameter(
          type: .string,
          description: "A short, concise name to summarize the food the user described."
        ),
        "foodItems": Schema.Parameter(
          description: "The individual food items described by the user. You should have high confidence these food items are what the user is referring to.",
          arrayOf: .AIEstimate.item
        ),
        "optionalFoodItems": Schema.Parameter(
          description: "Extra individual food items that may be present. This could be things like butter or cooking oil that the user forgot to mention, or food items that are commonly associated with the user's description. Only add FoodItemServings to this list if they are NOT included in `items` already. You should try and put 0 to 3 items in this list.",
          arrayOf: .AIEstimate.item
        )
      ],
      references: [
        "quantity": Schema.Object.quantity
      ]
    )
  )
}

extension Schema.Object {
  enum AIEstimate { }
}

extension Schema.Object.AIEstimate {
  static let item = Schema.Object(
    properties: [
      "name": Schema.Parameter(type: .string, description: "The name of the individual food item. Do not include the brand name or flavour here, if there are any. Capitalize the first letter in each word. Do not list the number of servings here."),
      "brandName": Schema.Parameter(type: .optionalString, description: "The brand name of the product, if known. If unknown, omit this property. Capitalize the first letter in each word."),
      "flavour": Schema.Parameter(type: .optionalString, description: "The flavour of the food item. This typically applies to branded products. If unknown, omit this property. Capitalize the first letter in each word. This should not contain the same value as name. ex 'name': 'Lemonade', 'flavour': 'Strawberry'"),
      "servingName": Schema.Parameter(type: .string, description: "A name for a single serving of the food item. E.g. 1 cup or 12 chips. It should not contain the name of the item itself, and should contain a number. This should be the typical standard serving unit for measuring this food item."),
      "servingValue": Schema.Parameter(ref: "quantity"),
      "servingCount": Schema.Parameter(type: .number, description: "The number of servings of the item."),
      "calories": Schema.Parameter(ref: "quantity"),
      "fat": Schema.Parameter(ref: "quantity"),
      "carbohydrates": Schema.Parameter(ref: "quantity"),
      "protein": Schema.Parameter(ref: "quantity"),
      "saturatedFat": Schema.Parameter(ref: "quantity"),
      "transFat": Schema.Parameter(ref: "quantity"),
      "polyunsaturatedFat": Schema.Parameter(ref: "quantity"),
      "monounsaturatedFat": Schema.Parameter(ref: "quantity"),
      "fiber": Schema.Parameter(ref: "quantity"),
      "sugar": Schema.Parameter(ref: "quantity"),
      "cholesterol": Schema.Parameter(ref: "quantity"),
      "sodium": Schema.Parameter(ref: "quantity"),
      "calcium": Schema.Parameter(ref: "quantity"),
      "iron": Schema.Parameter(ref: "quantity"),
      "potassium": Schema.Parameter(ref: "quantity"),
      "magnesium": Schema.Parameter(ref: "quantity"),
      "zinc": Schema.Parameter(ref: "quantity"),
      "vitaminA": Schema.Parameter(ref: "quantity"),
      "vitaminB6": Schema.Parameter(ref: "quantity"),
      "vitaminB12": Schema.Parameter(ref: "quantity"),
      "vitaminC": Schema.Parameter(ref: "quantity"),
      "vitaminD": Schema.Parameter(ref: "quantity"),
      "vitaminE": Schema.Parameter(ref: "quantity")
    ]
  )
}

// MARK: - Goals

extension ResponseSchema {
  static let suggestedGoals = ResponseSchema(
    name: "suggestedGoals",
    schema: Schema.Object(
      properties: [
        "suggestedGoals": Schema.Parameter(
          description: "A list of the suggested goals.",
          arrayOf: Schema.Object(
            properties: [
              "metric" : Schema.Parameter(
                enum: SuggestedGoal.Metric.self,
                description: "The metric that the goal will be measured by."
              ),
              "value" : Schema.Parameter(
                type: .number,
                description: "The numeric value of the goal."
              ),
              "unit" : Schema.Parameter(
                enum: SuggestedGoal.Unit.self,
                description: "The unit to measure the goal with."
              ),
              "notes" : Schema.Parameter(
                type: .string,
                description: "A short, 1 sentence note about why this goal is being recommended."
              )
            ]
          )
        ),
        "suggestedReminders": Schema.Parameter(
          description: "A list of things the user should be reminded to do. These should only be used when you can't use a goal.",
          arrayOf: Schema.Object(
            properties: [
              "title" : Schema.Parameter(
                type: .string,
                description: "The name of the reminder that will be displayed to the user. This should be 1-5 words. Examples: 'Stretch', 'Perform Breathing Exercises'"
              )
            ]
          )
        )
      ]
    )
  )
}

// MARK: - Schema.Object Primitives

extension Schema.Object {

  static let quantity = Schema.Object(
    properties: [
      "value": Schema.Parameter(
        type: .number,
        description: "The value of the quantity."
      ),
      "unit": Schema.Parameter(
        enum: Unit.self,
        description: "The unit of the quantity."
      )
    ]
  )

  enum Unit: String, Codable, CaseIterable {
    case g
    case mg
    case mcg
    case kcal
    case Cal
    case mL
    case oz
  }
}
