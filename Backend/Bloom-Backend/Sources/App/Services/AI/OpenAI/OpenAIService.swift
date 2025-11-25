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

struct OpenAIService: Sendable {
  let openAI: OpenAIKit.Client
  let gemini: OpenAIKit.Client
  let imageStorage: ImageStorage
  let logger: Logger

  init(
    openAI: OpenAIKit.Client,
    gemini: OpenAIKit.Client,
    imageStorage: ImageStorage,
    logger: Logger
  ) {
    self.openAI = openAI
    self.gemini = gemini
    self.imageStorage = imageStorage
    self.logger = logger
  }
}

extension OpenAIService {

  func generateConversationTitle(userMessage: String) async -> String? {
    do {
      let model = ModelID.OSeries.o4Mini

      let messages: [Chat.Message] = [
        Chat.Message(
          role: .system,
          content: [
            .text("Generate a concise title for this conversation based on the message. This title will be shown to the user to describe the conversation. It should summarize what you're chatting about. Respond with only the title, no quotes or punctuation.")
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .text(userMessage)
          ]
        )
      ]

      let response = try await openAI.chats.create(
        model: model,
        messages: messages
      )

      guard let text = response.choices.first?.message.content.first?.text else {
        return nil
      }

      return text.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
      logger.error("Failed to generate conversation title: \(error)")
      return nil
    }
  }

  func parseNewFoodItem(
    barCode: String,
    country: String,
    nutritionLabelMetadata: ImageFileMetadata,
    packagingMetadata: ImageFileMetadata
  ) async throws -> (FoodItemRecord?, UploadNewFoodResponse.Result) {

    let (nutritionData, packagingData) = await asyncParallelize {
      await parseNutritionLabel(
        nutritionLabelMetadata: nutritionLabelMetadata
      )
    } task2: {
      await parsePackaging(
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
    foodItemRecord.saturatedFat = nutritionData.saturatedFat?.nonZeroValue
    foodItemRecord.transFat = nutritionData.transFat?.nonZeroValue
    foodItemRecord.polyunsaturatedFat = nutritionData.polyunsaturatedFat?.nonZeroValue
    foodItemRecord.monounsaturatedFat = nutritionData.monounsaturatedFat?.nonZeroValue
    foodItemRecord.fiber = nutritionData.fiber?.nonZeroValue
    foodItemRecord.sugar = nutritionData.sugar?.nonZeroValue
    foodItemRecord.cholesterol = nutritionData.cholesterol?.nonZeroValue
    foodItemRecord.sodium = nutritionData.sodium?.nonZeroValue
    foodItemRecord.calcium = nutritionData.calcium?.nonZeroValue
    foodItemRecord.iron = nutritionData.iron?.nonZeroValue
    foodItemRecord.potassium = nutritionData.potassium?.nonZeroValue
    foodItemRecord.magnesium = nutritionData.magnesium?.nonZeroValue
    foodItemRecord.zinc = nutritionData.zinc?.nonZeroValue
    foodItemRecord.vitaminA = nutritionData.vitaminA?.nonZeroValue
    foodItemRecord.vitaminB6 = nutritionData.vitaminB6?.nonZeroValue
    foodItemRecord.vitaminB12 = nutritionData.vitaminB12?.nonZeroValue
    foodItemRecord.vitaminC = nutritionData.vitaminC?.nonZeroValue
    foodItemRecord.vitaminD = nutritionData.vitaminD?.nonZeroValue
    foodItemRecord.vitaminE = nutritionData.vitaminE?.nonZeroValue
    foodItemRecord.servingName = nutritionData.servingName
    foodItemRecord.servingValue = nutritionData.servingValue.value
    foodItemRecord.servingUnit = nutritionData.servingValue.unit

    return (foodItemRecord, .foodLogged)
  }

  func estimateCalories(
    foodImageFile: ImageFile,
    foodDescription: String?
  ) async -> OpenAIEstimateCaloriesResponse? {
    do {
      let model = ModelID.GPT4.gpt_4o_mini

      var messages: [Chat.Message] = [
        Chat.Message(
          role: .system,
          content: [
            .text(.Prompt.estimateCalories)
//            .text(try .Prompt.jsonSchemaDefinition(.aiEstimate))
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

      let response = try await openAI.chats.create(
        model: model,
        messages: messages,
        responseFormat: ResponseFormat(type: .jsonSchema(.aiEstimate))
      )

      return try response.parse(OpenAIEstimateCaloriesResponse.self)
    } catch {
      logger.error(error)
      return nil
    }
  }

  func estimateCaloriesV2(
    foodImageFile: ImageFile,
    foodDescription: String?
  ) async -> OpenAIEstimateCaloriesResponse? {
    do {
      let file = try await openAI.files.upload(
        file: foodImageFile.data,
        fileName: "image.\(foodImageFile.fileExtension)",
        purpose: .userData
      )

      var inputs = [OpenAIKit.Response.InputItem]()
      inputs.append(.message(.init(role: .user, content: [.image(.init(detail: .low, fileId: file.id))])))
      if let foodDescription {
        inputs.append(.message(.init(role: .user, content: [.text(.init(text: foodDescription))])))
      }

      let response = try await openAI.responses.createResponse(
        input: inputs,
        model: .GPT4.gpt_4o_mini,
        instructions: .Prompt.estimateCalories,
        text: Text(format: .init(type: .jsonSchema(.aiEstimate)))
      )

      return try response.parse(OpenAIEstimateCaloriesResponse.self)
    } catch {
      logger.error(error)
      return nil
    }
  }

  func estimateCalories(textDescription: String) async -> OpenAIEstimateCaloriesResponse? {
    do {
      let model = ModelID.GPT4.gpt_4o_mini

      let messages: [Chat.Message] = [
        Chat.Message(
          role: .system,
          content: [
            .text(.Prompt.estimateCaloriesByText)
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
        temperature: 0.3,
        topP: 0.6,
        responseFormat: ResponseFormat(type: .jsonSchema(.textAIEstimate))
      )

      return try response.parse(OpenAIEstimateCaloriesResponse.self)
    } catch {
      logger.error(error)
      return nil
    }
  }

  func estimateCaloriesV2(textDescription: String) async -> OpenAIEstimateCaloriesResponse? {
    do {
      var inputs = [OpenAIKit.Response.InputItem]()
      inputs.append(.message(.init(role: .user, content: [.text(.init(text: textDescription))])))

      let response = try await openAI.responses.createResponse(
        input: inputs,
        model: .GPT4.gpt_4o_mini,
        instructions: .Prompt.estimateCaloriesByText,
        text: Text(format: .init(type: .jsonSchema(.textAIEstimate)))
      )

      return try response.parse(OpenAIEstimateCaloriesResponse.self)
    } catch {
      logger.error(error)
      return nil
    }
  }

  func evaluateFoodItemAccuracy(
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
       let nutritionImageFile = try await imageStorage.retrieveImage(
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
       let packagingImageFile = try await imageStorage.retrieveImage(
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

    let response = try await openAI.chats.create(
      model: .GPT4.gpt_4o_mini,
      messages: messages
    )

    struct EvaluationResponse: Codable {
      let accuracyScore: Int
      let evaluationNotes: String
      let recommendations: [String: String]
    }

    guard let evaluation = try response.parse(EvaluationResponse.self) else {
      throw Abort(.internalServerError, reason: "Could not decode response.")
    }

    return (
      score: evaluation.accuracyScore,
      notes: evaluation.evaluationNotes,
      recommendations: evaluation.recommendations
    )
  }
}

private extension OpenAIService {

  func parseNutritionLabel(
    nutritionLabelMetadata: ImageFileMetadata
  ) async -> OpenAINutritionLabelParseResponse? {
    do {
      guard let imageFileExtension = nutritionLabelMetadata.fileExtension else {
        logger.warning("Image file extension could not be determined \(nutritionLabelMetadata.filename)")
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
        model: .GPT4.gpt_4o_mini,
        messages: messages,
        responseFormat: ResponseFormat(type: .jsonSchema(.nutritionLabelParse))
      )

      return try response.parse(OpenAINutritionLabelParseResponse.self)
    } catch {
      logger.error("Failed to parse nutrition label: \(error.localizedDescription)")
//      telemetryDeck.errorOccurred(
//        id: "OpenAIService.parseNutritionLabel",
//        message: error.localizedDescription
//      )
      return nil
    }
  }

  func parsePackaging(
    packagingMetadata: ImageFileMetadata
  ) async -> OpenAIPackagingParseResponse? {
    do {
      guard let fileExtension = packagingMetadata.fileExtension else {
        logger.warning("Image file extension could not be determined \(packagingMetadata.filename)")
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
        model: .GPT4.gpt_4o_mini,
        messages: messages,
        responseFormat: ResponseFormat(type: .jsonSchema(.packagingParse))
      )

      return try response.parse(OpenAIPackagingParseResponse.self)
    } catch {
      logger.error(error)
//      telemetryDeck.errorOccurred(
//        id: "OpenAIService.parsePackaging",
//        message: error.localizedDescription
//      )
      return nil
    }
  }
}

extension OpenAIService {

  func estimateCaloriesMagicScan(
    image: Data?,
    contextText: String?
  ) async throws -> [MagicScanStatusResponse.Serving] {
    let model = ModelID.GPT4.gpt_4o_mini

    var messages: [Chat.Message] = []

    if let image = image {
      // Image-based scan
      let imageProcessor = ImageProcessor()
      guard let imageType = imageProcessor.determineImageType(image) else {
        throw Abort(.badRequest, reason: "Unsupported image type")
      }

      messages = [
        Chat.Message(
          role: .system,
          content: [
            .text("Identify the food in this image and provide your best estimate of nutrients. Only include edible items. Be concise.")
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .imageData(image, "image/\(imageType)")
          ]
        )
      ]

      if let contextText = contextText, !contextText.isEmpty {
        messages.append(
          Chat.Message(
            role: .user,
            content: [
              .text(contextText)
            ]
          )
        )
      }
    } else if let contextText = contextText, !contextText.isEmpty {
      // Text-only scan
      messages = [
        Chat.Message(
          role: .system,
          content: [
            .text("Identify the food described and provide your best estimate of nutrients. Only include edible items. Be concise.")
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .text(contextText)
          ]
        )
      ]
    } else {
      throw Abort(.badRequest, reason: "Either image or contextText must be provided")
    }

    let response = try await openAI.chats.create(
      model: model,
      messages: messages,
      responseFormat: ResponseFormat(type: .jsonSchema(.magicScanEstimate))
    )

    guard let parsedResponse = try response.parse(OpenAIEstimateCaloriesResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse OpenAI response")
    }

    // Convert to MagicScanStatusResponse.Serving
    return parsedResponse.foodItems.map { item in
      MagicScanStatusResponse.Serving(
        servings: item.servingCount,
        item: item.asFoodItem()
      )
    }
  }

  /// AI-FIRST APPROACH: Single-pass comprehensive food detection and nutrition estimation.
  /// Detects all foods and estimates complete nutrition in one API call.
  /// Prioritizes main dishes over condiments and uses enhanced prompts for better accuracy.
  func detectAndEstimateFoodsMagicScan(
    image: Data?,
    contextText: String?
  ) async throws -> [MagicScanStatusResponse.Serving] {
    // Use GPT-4o for better vision capabilities
    let model = ModelID.GPT4.gpt_4o

    var messages: [Chat.Message] = []

    if let image = image {
      // Image-based comprehensive detection and estimation
      let imageProcessor = ImageProcessor()
      guard let imageType = imageProcessor.determineImageType(image) else {
        throw Abort(.badRequest, reason: "Unsupported image type")
      }

      messages = [
        Chat.Message(
          role: .system,
          content: [
            .text("""
              You are an expert nutritionist analyzing food images. Identify ALL visible foods and estimate their complete nutrition.

              PRIORITIES:
              1. Main dishes (proteins, starches, vegetables) FIRST
              2. Side dishes and accompaniments second
              3. Sauces, condiments, and garnishes last
              4. Do NOT mistake sauces for main items (e.g., "steak sauce" is NOT the same as "steak")

              For each food item:
              - Identify the actual food (e.g., "Grilled Steak", not "Steak Sauce" when you see a steak)
              - Estimate portion size in grams using visual cues:
                * Plate diameter (~26cm standard dinner plate)
                * Utensil size (fork ~20cm, knife ~23cm)
                * Hand comparisons (palm ~85g for protein)
                * Standard portions: chicken breast ~170g, 1 cup rice ~200g, 1 cup vegetables ~150g
              - Provide complete nutrition per serving

              VALIDATION:
              - Calories should ≈ 4×(protein+carbs in g) + 9×(fat in g)
              - Typical meal: 200-800 calories
              - Single serving: 50-500 calories
              - Be conservative if uncertain

              Detect brand names only if visible on packaging (labels, bottles, cans, boxes).
              """)
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .imageData(image, "image/\(imageType)")
          ]
        )
      ]

      if let contextText = contextText, !contextText.isEmpty {
        messages.append(
          Chat.Message(
            role: .user,
            content: [
              .text("Additional context: \(contextText)")
            ]
          )
        )
      }
    } else if let contextText = contextText, !contextText.isEmpty {
      // Text-only comprehensive detection and estimation
      messages = [
        Chat.Message(
          role: .system,
          content: [
            .text("""
              You are an expert nutritionist. Based on the user's description, identify all foods and estimate complete nutrition.

              Use standard portion sizes:
              - Protein (chicken, steak, fish): 170g
              - Grains (rice, pasta): 1 cup cooked = 200g
              - Vegetables: 1 cup = 150g
              - Fruits: 1 medium = 150g

              Provide complete nutrition per serving.
              Validate: calories ≈ 4×(protein+carbs in g) + 9×(fat in g)
              """)
          ]
        ),
        Chat.Message(
          role: .user,
          content: [
            .text(contextText)
          ]
        )
      ]
    } else {
      throw Abort(.badRequest, reason: "Either image or contextText must be provided")
    }

    let response = try await openAI.chats.create(
      model: model,
      messages: messages,
      responseFormat: ResponseFormat(type: .jsonSchema(.magicScanEstimate))
    )

    guard let parsedResponse = try response.parse(OpenAIEstimateCaloriesResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse OpenAI response")
    }

    // Convert to servings
    return parsedResponse.foodItems.map { item in
      MagicScanStatusResponse.Serving(
        servings: item.servingCount,
        item: item.asFoodItem()
      )
    }
  }
}

extension OpenAIService {

  func suggestGoals(
    healthData: String,
    currentGoals: String
  ) async throws -> SuggestGoalsResponse {
    let messages: [Chat.Message] = [
      Chat.Message(
        role: .system,
        content: [.text(.Prompt.suggestGoals)]
      ),
      Chat.Message(
        role: .system,
        content: [.text(SuggestedGoal.Metric.validUnitDescription)]
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

    let chat = try await openAI.chats.create(
      model: .GPT4.gpt_4o_mini,
      messages: messages,
      responseFormat: ResponseFormat(type: .jsonSchema(.suggestedGoals))
    )

    guard let response = try chat.parse(OpenAISuggestGoalsResponse.self) else {
      throw Abort(.internalServerError)
    }

    logger.info("AI Goal Thought Process")
    for (index, step) in response.thoughtProcess.enumerated() {
      logger.info("\(index + 1). \(step.step)")
    }

    return SuggestGoalsResponse(
      goals: response.suggestedGoals,
      reminders: response.suggestedReminders
    )
  }
}
