//
//  NetworkRequester.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import SwiftUI
import BloomModel

private extension String {
    static let usdaAPIKey = "d8qTh8MkWmXtiqUjVvO2dv7w64W9wDOTnAYY6pJa"

    static let bloomAPIBase = "https://bloom-api-5903aeb2ee43.herokuapp.com/"
}

final class NetworkRequester: Sendable {
    static let shared = NetworkRequester()
}

extension NetworkRequester {

    func foodAutocomplete(query: String) async throws -> [String] {
        let url = URL(string: .bloomAPIBase + "v1/food/autocomplete")!

        let request = FoodAutocompleteRequest(query: query)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try JSONEncoder.main.encode(request)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        let response = try JSONDecoder.main.decode(FoodAutocompleteResponse.self, from: data)

        return response.tokens
    }


    func foodSearch(name: String, brand: String?) async throws -> [FoodSearchResponse.Section] {
        let url = URL(string: .bloomAPIBase + "v1/food/search")!

        let request = FoodSearchRequest(
            name: name,
            brand: brand
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try JSONEncoder.main.encode(request)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        let response = try JSONDecoder.main.decode(FoodSearchResponse.self, from: data)

        return response.sections
    }

    func foodSearch(upcCode: String) async throws -> [FoodSearchResponse.Section] {
        let url = URL(string: .bloomAPIBase + "v1/food/search")!

        let request = FoodSearchRequest(
            upcCode: upcCode
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try JSONEncoder.main.encode(request)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        let response = try JSONDecoder.main.decode(FoodSearchResponse.self, from: data)

        return response.sections
    }

    func uploadFood(
        barcode: String,
        nutritionImage: UIImage,
        packagingImage: UIImage
    ) async throws -> UploadNewFoodResponse {
        let url = URL(string: .bloomAPIBase + "v1/food/upload")!

        guard
            let nutritionData = nutritionImage.pngData(),
            let packagingData = packagingImage.pngData()
        else {
            throw NSError(description: "There was an issue uploading the images.")
        }

        let request = UploadNewFoodRequest(
            barcode: barcode,
            nutritionLabelImage: .init(
                data: nutritionData,
                fileExtension: "png"
            ),
            packagingImage: .init(
                data: packagingData,
                fileExtension: "png"
            )
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try JSONEncoder.main.encode(request)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        let response = try JSONDecoder.init().decode(UploadNewFoodResponse.self, from: data)

        return response
    }
}

extension NetworkRequester {

    func sendQuery(
        userInfo: UserInfoModel?,
        currentGoals: [String],
        currentSupplements: [String],
        chatHistory: [ChatMessageHistory],
        learnedUserFacts: [String]
    ) async throws -> AskResponseModel {
        let request = AskRequestModel(
            userInfo: userInfo,
            currentSupplements: currentSupplements,
            currentGoals: currentGoals,
            chatHistory: chatHistory,
            learnedUserFacts: learnedUserFacts
        )

        let requestData = try JSONEncoder.main.encode(request)

        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/ask")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = requestData
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        return try JSONDecoder.main.decode(AskResponseModel.self, from: data)
    }

    func sendProactiveTip(
        request: ProactiveTipRequestModel
    ) async throws -> ProactiveTipResponseModel {

        let requestData = try JSONEncoder.main.encode(request)

        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/proactive-tip")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = requestData
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        return try JSONDecoder.main.decode(ProactiveTipResponseModel.self, from: data)
    }

    func fetchGoals() async throws -> [String] {
        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/goals?max=100")!
        let (data, _) = try await URLSession.shared.data(from: url)

        return try JSONDecoder.main.decode([String].self, from: data)
    }

    func fetchSupplements() async throws -> [String] {
        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/supplements?max=100")!
        let (data, _) = try await URLSession.shared.data(from: url)

        return try JSONDecoder.main.decode([String].self, from: data)
    }

    func parseOnboardingInfo(request: OnboardingInfoRequest) async throws -> OnboardingInfoResponse {
        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/onboarding-info")!

        let requestData = try JSONEncoder.main.encode(request)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = requestData
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        return try JSONDecoder.main.decode(OnboardingInfoResponse.self, from: data)
    }

    func askSleepCoach(request: SleepCoachRequest) async throws -> SleepCoachResponse {
        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/sleep-coach")!
        return try await URLSession.shared.post(url: url, request: request)
    }

    func chatSleepCoach(request: SleepCoachRequest) async throws -> SleepCoachResponse {
        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/sleep-coach-chat")!
        return try await URLSession.shared.post(url: url, request: request)
    }
}
