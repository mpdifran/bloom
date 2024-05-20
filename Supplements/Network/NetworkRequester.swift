//
//  NetworkRequester.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import SwiftUI

final class NetworkRequester {
    static let shared = NetworkRequester()

    private init() { }
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

        print("Request Data: \(String(data: requestData, encoding: .utf8) ?? "")")

        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/ask")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = requestData
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        print("Response Data: \(String(data: data, encoding: .utf8) ?? "")")

        return try JSONDecoder.main.decode(AskResponseModel.self, from: data)
    }

    func sendProactiveTip(
        request: ProactiveTipRequestModel
    ) async throws -> ProactiveTipResponseModel {

        let requestData = try JSONEncoder.main.encode(request)

        print("Request Data: \(String(data: requestData, encoding: .utf8) ?? "")")

        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/proactive-tip")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = requestData
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        print("Response Data: \(String(data: data, encoding: .utf8) ?? "")")

        return try JSONDecoder.main.decode(ProactiveTipResponseModel.self, from: data)
    }

    func fetchGoals() async throws -> [GoalModel] {
        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/goals?max=100")!
        let (data, _) = try await URLSession.shared.data(from: url)

        let goalsResponse = try JSONDecoder.main.decode([String].self, from: data)

        var goals = [GoalModel]()
        for index in 0 ..< goalsResponse.count {
            let goalName = goalsResponse[index]
            let color = Color.indexedSet(index: index)

            goals.append(GoalModel(name: goalName, color: color))
        }
        return goals
    }

    func fetchSupplements() async throws -> [String] {
        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/supplements?max=100")!
        let (data, _) = try await URLSession.shared.data(from: url)

        let supplementsResponse = try JSONDecoder.main.decode([String].self, from: data)

        return supplementsResponse
    }

    func fetchInsights(request: InsightsRequest) async throws -> InsightsResponse {
        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/insights")!
        
        let requestData = try JSONEncoder.main.encode(request)

        print("Request Data: \(String(data: requestData, encoding: .utf8) ?? "")")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = requestData
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        print("Response Data: \(String(data: data, encoding: .utf8) ?? "")")

        return try JSONDecoder.main.decode(InsightsResponse.self, from: data)
    }
}
