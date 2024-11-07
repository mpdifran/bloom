//
//  NetworkRequester.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import SwiftUI
import OpenAPIURLSession

private extension String {
    static let usdaAPIKey = "d8qTh8MkWmXtiqUjVvO2dv7w64W9wDOTnAYY6pJa"
    static let edamamAPIKey = "2e8d3fa598795c7616bd159abb9ff7ab"
    static let edamamAppID = "b6fefe5f"
}

final class NetworkRequester: Sendable {
    static let shared = NetworkRequester()
}

extension NetworkRequester {

    func edamamFoodAutocomplete(query: String) async throws -> [String] {
        let url = URL(string: "https://api.edamam.com/auto-complete")!.setting(
            queryItems: [
                URLQueryItem(name: "app_id", value: .edamamAppID),
                URLQueryItem(name: "app_key", value: .edamamAPIKey),
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "10")
            ]
        )!

        let urlRequest = URLRequest(url: url)

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        return try JSONDecoder.main.decode([String].self, from: data)
    }

    func edamamFoodSearch(query: String) async throws -> [Supplements.Components.Schemas.Food] {
        let client = Client(
            serverURL: try Servers.Server1.url(),
            transport: URLSessionTransport()
        )

        let input = Operations.get_sol_api_sol_food_hyphen_database_sol_v2_sol_parser.Input(
            query: .init(
                app_id: .edamamAppID,
                app_key: .edamamAPIKey,
                ingr: query,
                brand: query
            ),
            headers: .init()
        )

        let response = try await client.get_sol_api_sol_food_hyphen_database_sol_v2_sol_parser(input)

        let data = try response.ok.body.json.hints?.compactMap(\.food) ?? []
        print(data)
        return data
    }
}

extension NetworkRequester {

    func usdaFoodSearch(query: String) async throws -> USDAFoodSearchResponse {
        let request = USDAFoodSearchRequest(
            query: query,
            dataType: ["Foundation", "Branded", "SR Legacy"],
            pageSize: 10,
            pageNumber: 0,
            sortBy: "dataType.keyword",
            sortOrder: "asc"
        )

        let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=\(String.usdaAPIKey)")!
        let requestData = try JSONEncoder.main.encode(request)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        return try JSONDecoder.main.decode(USDAFoodSearchResponse.self, from: data)
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
