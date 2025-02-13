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
  You are a nutritionist, and your job is to estimate the nutrients in a photo of food.

  Your response must take the following JSON format:

  {
    "name": <A name for all the food you see in the photo>,
    "items": <An array of individual FoodItemServings identified in the photo. You should have high confidence that these food items exist in the photo>,
    "optional_items": <An array of extra individual FoodItemServings that may be in the photo. This could be things like butter or cooking oil that are difficult to identify from the photo, or an alternate food you have a low confidence on. Only add FoodItemServings to this list if they are NOT included in `items` already. You should try and put at least 5 items in this list.>
  }

  A FoodItemServing JSON object will have the following JSON format:

  {
    "name": <The name of the food item. The name should have the first letter of every word capitalized. This is required>,
    "serving_name": <Indicates the name of a single serving such as 1 bottle or 1 chicken breast. This should be a common measurable amount, and the lowest value possible. Make sure each word is lowercased. This is required>,
    "serving_value": <A required Quantity object. This should be the smallest unit of the food item, and be the measured amount for 'serving_name'. You will use 'serving_count' as a multiplier to indicate the total amount of food depicted by multiplying it by 'serving_value'>
    "serving_count": <How many servings of the food item are in the image, as a float. You are allowed to use fractions up to 2 decimal places. For example, if there are 2 chicken breasts, and each chicken breast is 120g, 'serving_value' is 120 g, and 'serving_count' is 2. This is required>
    "calories": <A required Quantity object where the unit is kcal, indicating the number of calories in the food item>
    "protein": <A required Quantity object where the unit is g, indicating the amount of protein in the food item>
    "carbohydrates": <A required Quantity object where the unit is g, indicating the amount of carbohydrates in the food item>
    "fat": <A required Quantity object where the unit is g, indicating the amount of fat in the food item>
    "saturated_fat": <An optional Quantity object where the unit is g indicating the amount of saturated fat in the food item>
    "trans_fat": <An optional Quantity object where the unit is g indicating the amount of trans fat in the food item>
    "polyunsaturated_fat": <An optional Quantity object where the unit is g indicating the amount of polyunsaturated fat in the food item>
    "monounsaturated_fat": <An optional Quantity object where the unit is g indicating the amount of monounsaturated fat in the food item>
    "fiber": <An optional Quantity object where the unit is g indicating the amount of fiber in the food item>
    "sugar": <An optional Quantity object where the unit is g indicating the amount of sugar in the food item>
    "cholesterol": <An optional Quantity object where the unit is mg indicating the amount of cholesterol in the food item>
    "sodium": <An optional Quantity object where the unit is mg indicating the amount of sodium in the food item>
    "calcium": <An optional Quantity object where the unit is mg indicating the amount of calcium in the food item>
    "iron": <An optional Quantity object where the unit is mg indicating the amount of iron in the food item>
    "potassium": <An optional Quantity object where the unit is mg indicating the amount of potassium in the food item>
    "magnesium": <An optional Quantity object where the unit is mg indicating the amount of magnesium in the food item>
    "zinc": <An optional Quantity object where the unit is mg indicating the amount of zinc in the food item>
    "vitamin_a": <An optional Quantity object where the unit is mcg indicating the amount of vitamin A in the food item>
    "vitamin_b6": <An optional Quantity object where the unit is mg indicating the amount of vitamin B6 in the food item>
    "vitamin_b12": <An optional Quantity object where the unit is mcg indicating the amount of vitamin B12 in the food item>
    "vitamin_c": <An optional Quantity object where the unit is mg indicating the amount of vitamin C in the food item>
    "vitamin_d": <An optional Quantity object where the unit is mcg indicating the amount of vitamin D in the food item>
    "vitamin_e": <An optional Quantity object where the unit is mg indicating the amount of vitamin E in the food item>
  }

  A Quantity object has the following format:

  {
    "value": <A double value indicating the quantity>,
    "unit": <A string value indicating the unit of the associated value>
  }
  
  Make sure all JSON keys are snake case.
"""
                 )
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .imageData(foodImageFile.data, "image/\(foodImageFile.fileExtension)"),
            .text("Estimate the nutrient information for each food in the image.")
          ]
        )
      ]

      let response = try await openAI.chats.create(
        model: Model.GPT4.gpt_4o_mini,
        messages: messages
      )

      guard var message = response.choices.first?.message.content.first?.text else { return nil }

      if message.hasPrefix("```json") {
          message.removeFirst("```json".count)
      }
      if message.hasSuffix("```") {
          message.removeLast("```".count)
      }
      message = message.trimmingCharacters(in: .whitespacesAndNewlines)

      guard let data = message.data(using: .utf8) else { return nil }

      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase

      do {
        return try decoder.decode(OpenAIEstimateCaloriesResponse.self, from: data)
      } catch {
        request.logger.error(.init(stringLiteral: String(data: data, encoding: .utf8) ?? ""))
        throw error
      }
    } catch {
      request.logger.error(.init(stringLiteral: error.localizedDescription))
      return nil
    }
  }

  func evaluateFoodItemAccuracy(
    request: Request,
    foodItemRecord: FoodItemRecord,
    totalNumberOfIssueReports: Int,
    sampleIssueReports: [FoodItemIssueReport]
  ) async throws -> (score: Int, notes: String, recommendations: [String: String]) {
    var messages: [Chat.Message] = [
      Chat.Message(
        role: .system,
        content: [
          .text("""
          You are an expert nutritionist and food data analyst. Your PRIMARY task is to verify that the food item record matches the provided nutrition label and packaging images. Then, use your professional nutrition expertise to evaluate if the nutritional values make sense.

          IMPORTANT: Pay special attention to the downvote count - a high number of downvotes strongly indicates data inaccuracy and should significantly impact the accuracy score.

          You must respond in JSON format with the following structure:
          {
            "accuracy_score": A score from 0 to 100 indicating overall data accuracy and completeness,
            "evaluation_notes": A brief (2-3 sentences) summary of key issues found,
            "recommendations": A dictionary mapping field names to their recommended correct values, all value should be in string forms as well
          }

          Example response:
          {
            "accuracy_score": 70,
            "evaluation_notes": "Values in record do not match nutrition label image. Protein content also appears physiologically unreasonable for this food type.",
            "recommendations": { }
          }
          
          Rules for Recommendations:
          You will receive a food record, please only include fields that were provided to you.
          Only suggest corrections if a value clearly does not match the provided nutrition label or packaging images.
          DO NOT recommend corrections for missing values.
          Ensure that field names in recommendations exactly match those from the provided food item record.
          
          Key Considerations:
          Match between the food record and provided images – THIS IS THE PRIMARY FOCUS.
          User feedback (downvote count) – A high downvote count and issue reports strongly indicates data inaccuracy and should significantly impact the accuracy score. THIS IS CRITICAL.
          Restraint in recommendations – Only suggest corrections if you are certain that the value does not match the provided nutrition label or packaging.
          Professional assessment of nutritional values – Ensure values are within physiologically reasonable ranges.
          Completeness of nutritional information – Check if required fields are missing.
          Consistency across values – e.g., total fat vs. sum of fat types.
          Serving size appropriateness – Ensure serving sizes align with typical industry standards.
          Brand and product name accuracy – Confirm that branding details match the provided packaging.
          """)
        ]
      ),
      Chat.Message(
        role: .system,
        content: [
          .text("""
          Assign an accuracy score (0-100) based on the following factors:

          0-25 (Severe Inaccuracy) → The food record is highly unreliable. Multiple major mismatches with the nutrition label, critical missing fields (e.g., calories, serving size), or physiologically impossible values. High downvote count or high number of issue reports strongly reinforces inaccuracy.
          26-50 (Moderate Issues) → Some key fields match, but notable errors exist. Examples include incorrect serving sizes, sum of macronutrients not aligning with total values, or inconsistent calorie calculations. Moderate downvote count indicates user-reported issues.
          51-75 (Minor Issues) → The record is mostly accurate, with small discrepancies in nutrient values. Minor fields may be missing (e.g., dietary fiber, micronutrients), but core data is correct. Low to moderate downvote count suggests minor concerns.
          76-100 (Highly Accurate) → The record closely matches the provided nutrition label. No major inconsistencies in calories, macronutrients, or serving size. Low or no downvotes indicate high user confidence. Small non-essential fields may be missing but do not impact accuracy significantly.
          
          Consider user feedback (downvote count), data consistency, and number of issue reports when determining the final score.
          """)
        ]
      )
    ]

    // Just dump the entire object
    messages.append(Chat.Message(
      role: .user,
      content: [.text("Evaluate this food item record: \(foodItemRecord.prettyPrint())")]
    ))
    
    messages.append(Chat.Message(
      role: .user,
      content: [.text("There are \(totalNumberOfIssueReports) reports filed by users for this food item record.")]
    ))
    
    if sampleIssueReports.isNotEmpty {
      messages.append(Chat.Message(
        role: .user,
        content: [.text("Here are some sample reports filed by users: \(sampleIssueReports.map { $0.prettyPrint() }.joined(separator: "\n"))")]
      ))
    }
    
    // Add images if available
    if let nutritionLabelImage = foodItemRecord.nutritionLabelImage,
       let nutritionImageFile = try await request.imageStorage.retrieveImage(
         fileName: nutritionLabelImage,
         path: .nutritionLabel
       ) {
      messages.append(Chat.Message(
        role: .user,
        content: [
          .imageData(nutritionImageFile.data, "image/\(nutritionImageFile.fileExtension)"),
          .text("This is the nutrition label image for the product. Use it to verify the nutritional information.")
        ]
      ))
    }

    if let packagingImage = foodItemRecord.packagingImage,
       let packagingImageFile = try await request.imageStorage.retrieveImage(
         fileName: packagingImage,
         path: .foodPackaging
       ) {
      messages.append(Chat.Message(
        role: .user,
        content: [
          .imageData(packagingImageFile.data, "image/\(packagingImageFile.fileExtension)"),
          .text("This is the packaging image for the product. Use it to verify the product name, brand, and other visible information.")
        ]
      ))
    }

    let response = try await request.openAI.chats.create(
      model: Model.GPT4.gpt_4o_mini,
      messages: messages
    )

    guard var message = response.choices.first?.message.content.first?.text else {
      throw Abort(.internalServerError, reason: "No response from OpenAI")
    }

    // Clean up JSON string
    if message.hasPrefix("```json") {
      message.removeFirst("```json".count)
      message.removeLast("```".count)
    }
    message = message.trimmingCharacters(in: .whitespacesAndNewlines)

    guard let data = message.data(using: .utf8) else {
      throw Abort(.internalServerError, reason: "Could not encode OpenAI response")
    }

    struct EvaluationResponse: Codable {
      let accuracyScore: Int
      let evaluationNotes: String
      let recommendations: [String: String]
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    let evaluation = try decoder.decode(EvaluationResponse.self, from: data)
    
    return (
      score: evaluation.accuracyScore,
      notes: evaluation.evaluationNotes,
      recommendations: evaluation.recommendations
    )
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
                        - Property called 'serving_value' which contains a 'unit' property (like fl oz or g) and a 'value' property (numeric value for the unit) 
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
                        
                        If the nutrition label is in French, translate it to English.
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
