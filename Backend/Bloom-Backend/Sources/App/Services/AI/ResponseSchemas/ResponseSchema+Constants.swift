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
        "quantity": Schema.Object(
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
      ]
    )
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
                description: "A short, 1 sentence note about the goal."
              )
            ]
          )
        )
      ]
    )
  )
}


