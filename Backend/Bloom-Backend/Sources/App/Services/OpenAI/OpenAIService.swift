//
//  OpenAIService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import BloomModel
import Foundation
import Logging
import OpenAIKit
import Vapor

struct OpenAIService { }

extension OpenAIService {

  func parseNewFoodItem(
    request: Request,
    barCode: String,
    country: FoodItemRecord.Country,
    nutritionLabelMetadata: ImageFileMetadata,
    packagingMetadata: ImageFileMetadata
  ) async throws -> (FoodItemRecord?, UploadNewFoodResponse.Result) {

    let (nutritionData, packagingData) = await asyncParallelize {
      await parseNutritionLabel(
        request: request,
        nutritionLabelMetadata: nutritionLabelMetadata
      )
    } task2: {
      await parsePackaging(
        request: request,
        packagingMetadata: packagingMetadata
      )
    }

    // Validate the results
    guard let nutritionData else { return (nil, .unclearNutritionLabel) }
    guard let packagingData else { return (nil, .unclearPackaging) }

    let foodItemRecord = FoodItemRecord(
      id: UUID().uuidString,
      name: packagingData.productName,
      country: country,
      category: .branded,
      source: "Bloom"
    )

    foodItemRecord.brandName = packagingData.brandName
    foodItemRecord.flavour = packagingData.flavour
    foodItemRecord.barcode = barCode
    foodItemRecord.nutritionLabelImage = nutritionLabelMetadata.filename
    foodItemRecord.packagingImage = packagingMetadata.filename
    foodItemRecord.calories = nutritionData.calories.value
    foodItemRecord.protein = nutritionData.protein.value
    foodItemRecord.carbohydrates = nutritionData.carbohydrate.value
    foodItemRecord.fat = nutritionData.fat.value
    foodItemRecord.saturatedFat = nutritionData.saturatedFat?.value
    foodItemRecord.transFat = nutritionData.transFat?.value
    foodItemRecord.polyunsaturatedFat = nutritionData.polyunsaturatedFat?.value
    foodItemRecord.monounsaturatedFat = nutritionData.monounsaturatedFat?.value
    foodItemRecord.fiber = nutritionData.fiber?.value
    foodItemRecord.sugar = nutritionData.sugar?.value
    foodItemRecord.cholesterol = nutritionData.cholesterol?.value
    foodItemRecord.sodium = nutritionData.sodium?.value
    foodItemRecord.calcium = nutritionData.calcium?.value
    foodItemRecord.iron = nutritionData.iron?.value
    foodItemRecord.potassium = nutritionData.potassium?.value
    foodItemRecord.magnesium = nutritionData.magnesium?.value
    foodItemRecord.zinc = nutritionData.zinc?.value
    foodItemRecord.vitaminA = nutritionData.vitaminA?.value
    foodItemRecord.vitaminB6 = nutritionData.vitaminB6?.value
    foodItemRecord.vitaminB12 = nutritionData.vitaminB12?.value
    foodItemRecord.vitaminC = nutritionData.vitaminC?.value
    foodItemRecord.vitaminD = nutritionData.vitaminD?.value
    foodItemRecord.vitaminE = nutritionData.vitaminE?.value
    foodItemRecord.servingName = nutritionData.servingName
    foodItemRecord.servingValue = nutritionData.servingValue.value
    foodItemRecord.servingUnit = nutritionData.servingValue.unit

    return (foodItemRecord, .foodLogged)
  }

  func estimateCalories(
    request: Request,
    foodImageFile: ImageFile
  ) async -> OpenAIEstimateCaloriesResponse? {
    do {
      let openAI = request.openAI

      let messages: [Chat.Message] = [
        Chat.Message(
          role: .system,
          content: [
            .text("""
  You must respond in JSON. There should be a list of objects, one for each food item. Each object should have the following properties:
  - Property called 'name' that is the name of the food item. The name should have the first letter of every word capitalized.
  - Property called 'serving_name' which indicates the kind of serving such as 1 chicken breast or 1 piece of toast. This should be a common measurable amount, and the lowest value possible. Make sure each word is lowercased.
  - Property called 'serving_amount_unit' which indicates a measurable unit for the serving, such as g, cups, mL, or oz. 
  - Property called 'serving_amount' indicates the size of the serving, such as 1 or 100. This should be a float in relation to the serving_quantity. If the serving_amount_unit is g and there are 100 g in a chicken breast, and there are 2 chicken breats in a serving - then the value of this property should be 200.
  - Property called 'serving_count' which indicates how many servings of the food item are in the image.
  - Property called 'calories' which is a numerical float of the calories of the item per serving.
  - Property called 'protein', an numerical float of how many grams of protein per serving.
  - Property called 'carbs', an numerical float of how many grams of carbs per serving.
  - Property called 'fat', a numerical float of how many grams of fat per serving.
  - Property called 'saturated_fat', a numerical float of how many grams of saturated fat per serving.
  - Property called 'trans_fat', a numerical float of how many grams of trans fat per serving.
  - Property called 'polyunsaturated_fat', a numerical float of how many grams of polyunsaturated fat per serving.
  - Property called 'monounsaturated_fat', a numerical float of how many grams of monounsaturated fat per serving.
  - Property called 'fiber', a numerical float of how many grams of fiber per serving.
  - Property called 'sugar', a numerical float of how many grams of sugar per serving.
  - Property called 'cholesterol', a numerical float of how many milligrams of cholesterol per serving.
  - Property called 'sodium', a numerical float of how many milligrams of sodium per serving.
  - Property called 'calcium', a numerical float of how many milligrams of calcium per serving.
  - Property called 'iron', a numerical float of how many milligrams of iron per serving.
  - Property called 'potassium', a numerical float of how many milligrams of potassium per serving.
  - Property called 'magnesium', a numerical float of how many milligrams of magnesium per serving.
  - Property called 'zinc', a numerical float of how many milligrams of zinc per serving.
  - Property called 'vitamin_a', a numerical float of how many milligrams of vitamin A per serving.
  - Property called 'vitamin_b6', a numerical float of how many milligrams of vitamin B6 per serving.
  - Property called 'vitamin_b12', a numerical float of how many milligrams of vitamin b12 per serving.
  - Property called 'vitamin_c', a numerical float of how many milligrams of vitamin C per serving.
  - Property called 'vitamin_d', a numerical float of how many milligrams of vitamin D per serving.
  - Property called 'vitamin_e', a numerical float of how many milligrams of vitamin E per serving.
  
  Make sure all JSON keys are snake case. Make sure to estimate every kind of nutrient you think are in the food item.
"""
                 )
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .imageData(foodImageFile.data, "image/\(foodImageFile.fileExtension)"),
            .text("Estimate the nutrient information for each food item in the image.")
          ]
        )
      ]

      let response = try await openAI.chats.create(
        model: Model.GPT4.gpt_4o_mini,
        messages: messages
      )


      guard var message = response.choices.first?.message.content.first?.text else { return nil }

      message.removeFirst("```json".count)
      message.removeLast("```".count)
      message = message.trimmingCharacters(in: .whitespacesAndNewlines)

      guard let data = message.data(using: .utf8) else { return nil }

      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase

      let returnValue = try decoder.decode([OpenAIEstimateCaloriesResponse.Item].self, from: data)
      return OpenAIEstimateCaloriesResponse(items: returnValue)
    } catch {
      request.logger.error(.init(stringLiteral: error.localizedDescription))
      return nil
    }
  }
}

private extension OpenAIService {

  func parseNutritionLabel(
    request: Request,
    nutritionLabelMetadata: ImageFileMetadata
  ) async -> OpenAINutritionLabelParseResponse? {
    do {
      let openAI = request.openAI

      guard let imageFileExtension = nutritionLabelMetadata.fileExtension else {
        request.logger.warning("Image file extension could not be determined \(nutritionLabelMetadata.filename)")
        return nil
      }

      let messages: [Chat.Message] = [
        Chat.Message(
          role: .system,
          content: [
            .text("""
                        You must respond in JSON. There should be a single object.
                        
                        The properties of the object are:
                        
                        - Property called 'serving_name' which indicates the kind of serving such as 1 bottle or 2 brownies.
                        - Property called 'serving_value' which contains a unit property (like fl oz or g) and a value property (numeric value for the unit) 
                        - Property called 'calories' which contains a 'unit' property (kcal or Cal) and a 'value' property for the number of calories.
                        - Property called 'protein' which contains a 'unit' property (such as g) and a 'value'.
                        - Property called 'carbohydrate' which contains a 'unit' property (such as g) and a 'value'.
                        - Property called 'fat' which contains a 'unit' property (such as g) and a 'value'.
                        - Optional property called 'saturated_fat' which contains a 'unit' property (such as g) and a 'value'.
                        - Optional property called 'trans_fat' which contains a 'unit' property (such as g) and a 'value'.
                        - Optional property called 'polyunsaturated_fat' which contains a 'unit' property (such as g) and a 'value'.
                        - Optional property called 'monounsaturated_fat' which contains a 'unit' property (such as g) and a 'value'.
                        - Optional property called 'fiber' which contains a 'unit' property (such as g) and a 'value'.
                        - Optional property called 'sugar' which contains a 'unit' property (such as g) and a 'value'.
                        - Optional property called 'cholesterol' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'sodium' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'calcium' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'iron' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'potassium' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'magnesium' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'zinc' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'vitamin_a' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'vitamin_b6' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'vitamin_b12' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'vitamin_c' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'vitamin_d' which contains a 'unit' property (such as mg) and a 'value'.
                        - Optional property called 'vitamin_e' which contains a 'unit' property (such as mg) and a 'value'.
                        """)
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .imageData(nutritionLabelMetadata.data, "image/\(imageFileExtension)"),
            .text("Return the nutrition information from this image.")
          ]
        )
      ]

      let response = try await openAI.chats.create(
        model: Model.GPT4.gpt_4o_mini,
        messages: messages
      )

      guard var message = response.choices.first?.message.content.first?.text else { return nil }

      message.removeFirst("```json".count)
      message.removeLast("```".count)
      message = message.trimmingCharacters(in: .whitespacesAndNewlines)

      guard let data = message.data(using: .utf8) else { return nil }

      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase

      return try decoder.decode(OpenAINutritionLabelParseResponse.self, from: data)
    } catch {
      request.logger.error("Failed to parse nutrition label: \(error.localizedDescription)")
      //            request.telemetryDeck.errorOccurred(
      //                id: "OpenAIService.parseNutritionLabel",
      //                message: error.localizedDescription
      //            )
      return nil
    }
  }

  func parsePackaging(
    request: Request,
    packagingMetadata: ImageFileMetadata
  ) async -> OpenAIPackagingParseResponse? {
    do {
      let openAI = request.openAI

      guard let fileExtension = packagingMetadata.fileExtension else {
        request.logger.warning("Image file extension could not be determined \(packagingMetadata.filename)")
        return nil
      }

      let messages: [Chat.Message] = [
        Chat.Message(
          role: .system,
          content: [
            .text("You must respond in JSON. There should be a single object three properties: brand_name, product_name, and flavour (optional). Each property is a string in English populated with data from the image. Ensure the JSON keys are formatted in snake case. The detected strings should have the first letter of each word capitalized. If the detected text is in French, translate it to English, or just use the English text in the image.")
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .imageData(packagingMetadata.data, "image/\(fileExtension)"),
            .text("Return the brand name, product name, and any flavour (it there is one) you see in the packaging.")
          ]
        )
      ]

      let response = try await openAI.chats.create(
        model: Model.GPT4.gpt_4o_mini,
        messages: messages
      )

      guard var message = response.choices.first?.message.content.first?.text else { return nil }

      message.removeFirst("```json".count)
      message.removeLast("```".count)
      message = message.trimmingCharacters(in: .whitespacesAndNewlines)

      guard let data = message.data(using: .utf8) else { return nil }

      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase

      return try decoder.decode(OpenAIPackagingParseResponse.self, from: data)
    } catch {
      request.logger.error(.init(stringLiteral: error.localizedDescription))
      //            request.telemetryDeck.errorOccurred(
      //                id: "OpenAIService.parsePackaging",
      //                message: error.localizedDescription
      //            )
      return nil
    }
  }
}
