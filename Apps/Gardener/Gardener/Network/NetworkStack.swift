//
//  NetworkStack.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import Foundation
import BloomModel

final class NetworkStack: Sendable {

}

extension NetworkStack {

    func post<Content, Response>(
        url: URL,
        body: Content,
        response: Response.Type
    ) async throws -> Response where Content: Encodable, Response: Decodable {

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try JSONEncoder.bloomModel.encode(body)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        return try JSONDecoder.bloomModel.decode(Response.self, from: data)
    }
}
