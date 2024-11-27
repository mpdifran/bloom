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
        country: FoodCountry,
        nutritionLabelMetadata: ImageFileMetadata,
        packagingMetadata: ImageFileMetadata
    ) async throws -> (FoodItemRecord?, UploadNewFoodResponse.Result) {

        guard let nutritionData = await parseNutritionLabel(
            request: request,
            nutritionLabelMetadata: nutritionLabelMetadata
        ) else {
            return (nil, .unclearNutritionLabel)
        }

        guard let packagingData = await parsePackaging(
            request: request,
            packagingMetadata: packagingMetadata
        ) else {
            return (nil, .unclearPackaging)
        }

        let countryEnum: FoodItemRecord.Country
        switch country {
        case .usa:
            countryEnum = .usa
        case .canada:
            countryEnum = .canada
        }

        let foodItemRecord = FoodItemRecord(
            id: UUID().uuidString,
            name: packagingData.productName,
            country: countryEnum,
            category: .branded
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
  - Property called 'serving_name' which indicates the kind of serving such as 1 Chicken Breast or 3 Pieces of Toast. This should be a common measurable amount, and the lowest value possible. Make sure to capitalize the first letter in each word.
  - Property called 'serving_amount_unit' which indicates a measurable unit for the serving, such as g, cups, mL, or oz. 
  - Property called 'serving_amount' indicates the size of the serving, such as 1 or 100. This should be a float in relation to the serving_quantity. If the serving_name is g and there are 100 g in a chicken breats, and there are 2 chicken breats in a serving - then this should be 200 since it is 100 g per breast, and there's 2 chicken breasts in a serving.
  - Property called 'serving_count' which indicates how many servings of the food item are in the image.
  - Property called 'calories' which is a numerical float of the calories of the item per serving.
  - Property called 'fat', a numerical float of how many grams of fat per serving.
  - Property called 'carbs', an numerical float of how many grams of carbs per serving.
  - Property called 'protein', an numerical float of how many grams of protein per serving.
  Make sure all JSON keys are snake case.
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
                        - Property called 'serving_value' which contains a unit property (like fl oz or grams) and a value property (numeric value for the unit) 
                        - Property called 'calories' which contains a unit property (kcal or Cal) and a value property for the number of calories.
                        - Property called 'fat' which contains a unit property (such as grams or oz) and a value.
                        - Property called 'carbohydrate' which contains a unit property (such as grams or oz) and a value.
                        - Property called 'protein' which contains a unit property (such as grams or oz) and a value.
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
                        .text("You must respond in JSON. There should be a single object three properties: brand_name, product_name, and flavour (optional). Each property is a string populated with data from the image. Ensure the JSON keys are formatted in snake case. The detected strings should have the first letter of each word capitalized.")
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
