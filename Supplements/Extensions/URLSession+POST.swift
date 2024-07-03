//
//  URLSession+POST.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-03.
//

import Foundation

extension URLSession {

    func post<Request, Response>(url: URL, request: Request) async throws -> Response where Request: Encodable, Response: Decodable {
        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = 90
        urlRequest.httpBody = try JSONEncoder.main.encode(request)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: urlRequest)

        print(String(data: data, encoding: .utf8) ?? "")

        return try JSONDecoder.main.decode(Response.self, from: data)
    }
}
