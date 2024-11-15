//
//  OpenAIService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor
import OpenAIKit
import BloomModel

struct OpenAIService { }

extension OpenAIService {

    func parseNewFoodItem(
        request: Request,
        barCode: String,
        country: String,
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
        switch country.lowercased() {
        case "usa", "united states of america", "america", "us":
            countryEnum = .usa
        default:
            countryEnum = .canada
        }

        let foodItemRecord = FoodItemRecord(
            name: packagingData.productName,
            country: countryEnum
        )

        foodItemRecord.barcode = barCode
        foodItemRecord.brandName = packagingData.brandName
        foodItemRecord.flavour = packagingData.flavour
        foodItemRecord.category = .branded
        foodItemRecord.nutritionLabelImage = nutritionLabelMetadata.filename
        foodItemRecord.packagingImage = packagingMetadata.filename
        foodItemRecord.calories = nutritionData.calories.value
        foodItemRecord.protien = nutritionData.protein.value
        foodItemRecord.carbohydrates = nutritionData.carbohydrate.value
        foodItemRecord.fat = nutritionData.fat.value
        foodItemRecord.servingName = nutritionData.servingName
        foodItemRecord.servingValue = nutritionData.servingValue.value
        foodItemRecord.servingUnit = nutritionData.servingValue.unit

        return (foodItemRecord, .foodLogged)
    }
}

private extension OpenAIService {

    func parseNutritionLabel(
        request: Request,
        nutritionLabelMetadata: ImageFileMetadata
    ) async -> OpenAINutritionLabelParseResponse? {
        do {
            let openAI = request.openAI

            let messages: [Chat.Message] = [
                Chat.Message(
                    role: .system,
                    content: [
                        .text("You must respond in JSON. There should be a single object with properties for each nutrient. The value should be an object that contains a double for the value and a string for the unit. Only include the mass, not the daily percentage. Make sure to include calories as well. For the serving, use a property called 'serving_name' that is the name of one serving, and 'serving_value' that is the numerical value of a serving (this should be an object with value: double and unit: string as well). Make sure all JSON keys are snake case.")
                    ]
                ),
                Chat.Message(
                    role: .user,
                    content: [
                        .imageData(nutritionLabelMetadata.data, "image/png"),
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
            request.logger.error(.init(stringLiteral: error.localizedDescription))
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
                        .imageData(packagingMetadata.data, "image/png"),
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
