//
//  NetworkRequester.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

final class NetworkRequester {
    static let shared = NetworkRequester()

    private init() { }
}

extension NetworkRequester {

    func sendQuery(prompt: String, userInfo: UserInfoModel?) async throws -> ChatResponseModel {
        let request = ChatRequestModel(
            question: prompt
//            userInfo: userInfo
        )

        let requestData = try JSONEncoder.main.encode(request)

        let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/ask")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = requestData
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        let chatResponse = try JSONDecoder.main.decode(ChatResponseModel.self, from: data)

        return chatResponse
    }
}
