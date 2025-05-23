//
//  DetectedFoodParsingTests.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-23.
//

@testable import App
import XCTVapor
import Testing
import BloomModel

@Suite("DetectedFoodParsingTests")
struct DetectedFoodParsingTests {

  private let decoder = JSONDecoder.bloomModel

  @Test(arguments: [
    String.AIJSON.turkeySandwich
  ])
  func parsingJSONFromAI(
    inputJSON: String
  ) async throws {
    let data = inputJSON.data(using: .utf8)!

    let sut = try decoder.decode(DetectedFood.self, from: data)

    #expect(sut.foodItems.count == 4)
  }
}

private extension String {
  enum AIJSON { }
}

private extension String.AIJSON {
  static let turkeySandwich: String = """
    {
      "meal": "lunch",
      "name": "Turkey Sandwich on Whole Wheat Bread",
      "foodItems": [
        {
          "name": "Whole Wheat Bread",
          "servingCount": 2,
          "servingName": "2 slices",
          "calories": 140,
          "protein": 6,
          "fat": 2,
          "carbohydrates": 24,
          "fiber": 4,
          "sugar": 2,
          "sodium": 300
        },
        {
          "name": "Turkey",
          "servingCount": 4,
          "servingName": "4 oz",
          "calories": 120,
          "protein": 28,
          "fat": 1.5,
          "carbohydrates": 0,
          "fiber": 0,
          "sugar": 0,
          "sodium": 600
        },
        {
          "name": "Lettuce",
          "servingCount": 1,
          "servingName": "1 leaf",
          "calories": 1,
          "protein": 0.1,
          "fat": 0,
          "carbohydrates": 0.2,
          "fiber": 0.1,
          "sugar": 0,
          "sodium": 1
        },
        {
          "name": "Tomato",
          "servingCount": 2,
          "servingName": "2 slices",
          "calories": 5,
          "protein": 0.5,
          "fat": 0,
          "carbohydrates": 1,
          "fiber": 0.2,
          "sugar": 0.5,
          "sodium": 1
        }
      ]
    }
    """
}
