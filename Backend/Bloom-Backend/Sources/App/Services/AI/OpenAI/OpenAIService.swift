//
//  OpenAIService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import BloomModel
import Foundation
import Logging
@preconcurrency import OpenAIKit
import Vapor
import AppFoundations

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
    _ request: Request,
    foodImageFile: ImageFile,
    foodDescription: String?
  ) async -> OpenAIEstimateCaloriesResponse? {
    do {
      let openAI = request.gemini
      let model = Model.Gemini.flash2_0

      var messages: [Chat.Message] = [
        Chat.Message(
          role: .system,
          content: [
            .text(.Prompt.estimateCalories),
            .text(try .Prompt.jsonSchemaDefinition(.aiEstimate))
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .imageData(foodImageFile.data, "image/\(foodImageFile.fileExtension)")
          ]
        )
      ]

      if let foodDescription {
        messages.append(
          Chat.Message(
            role: .user,
            content: [
              .text(foodDescription)
            ]
          )
        )
      }

      let response = try await openAI.chats.create(model: model, messages: messages)

      return try response.parse(OpenAIEstimateCaloriesResponse.self)
    } catch {
      request.logger.error(error)
      return nil
    }
  }

  func estimateCalories(_ request: Request, textDescription: String) async -> OpenAIEstimateCaloriesResponse? {
    do {
      let openAI = request.openAI
      let model = Model.GPT4.gpt_4o_mini

      let messages: [Chat.Message] = [
        Chat.Message(
          role: .system,
          content: [
            .text(.Prompt.estimateCaloriesByText)
//            .text(try .Prompt.jsonSchemaDefinition(.textAIEstimate))
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .text(textDescription)
          ]
        )
      ]

      let response = try await openAI.chats.create(
        model: model,
        messages: messages,
        temperature: 0.1,
        topP: 0.4,
        responseFormat: ResponseFormat(type: .jsonSchema(.textAIEstimate))
      )

//      if var message = response.choices.first?.message.content.first?.text {
//        request.logger.info(message)
//      }

      return try response.parse(OpenAIEstimateCaloriesResponse.self)
    } catch {
      request.logger.error(error)
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
    }
    if message.hasSuffix("```") {
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
            .text(.Prompt.nutritionLabelParse)
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
        messages: messages,
        responseFormat: ResponseFormat(type: .jsonSchema(.nutritionLabelParse))
      )

      return try response.parse(OpenAINutritionLabelParseResponse.self)
    } catch {
      request.logger.error("Failed to parse nutrition label: \(error.localizedDescription)")
//      request.telemetryDeck.errorOccurred(
//        id: "OpenAIService.parseNutritionLabel",
//        message: error.localizedDescription
//      )
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
            .text(.Prompt.packagingParse)
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .imageData(packagingMetadata.data, "image/\(fileExtension)"),
            .text("Return the brand name, product name, and any flavour (it there is one).")
          ]
        )
      ]

      let response = try await openAI.chats.create(
        model: Model.GPT4.gpt_4o_mini,
        messages: messages,
        responseFormat: ResponseFormat(type: .jsonSchema(.packagingParse))
      )

      return try response.parse(OpenAIPackagingParseResponse.self)
    } catch {
      request.logger.error(error)
//      request.telemetryDeck.errorOccurred(
//        id: "OpenAIService.parsePackaging",
//        message: error.localizedDescription
//      )
      return nil
    }
  }
}

extension OpenAIService {

  func suggestGoals(
    _ request: Request,
    healthData: String,
    currentGoals: String
  ) async throws -> SuggestGoalsResponse {
    let messages: [Chat.Message] = [
      Chat.Message(
        role: .system,
        content: [.text(.Prompt.suggestGoals)]
      ),
      Chat.Message(
        role: .user,
        content: [.text("Here is my health data:\n\n```json\n\(healthData)\n```\n")]
      ),
      Chat.Message(
        role: .user,
        content: [.text("Here are my current goals:\n\n```json\n\(currentGoals)\n```\n")]
      )
    ]

    let chat = try await request.openAI.chats.create(
      model: Model.GPT4.gpt_4o_mini,
      messages: messages,
      responseFormat: ResponseFormat(type: .jsonSchema(.suggestedGoals))
    )

    guard let response = try chat.parse(OpenAISuggestGoalsResponse.self) else {
      throw Abort(.internalServerError)
    }

    return SuggestGoalsResponse(
      goals: response.suggestedGoals,
      reminders: response.suggestedReminders
    )
  }
}
