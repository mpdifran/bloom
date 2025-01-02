//
//  URLRequest+Endpoints.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-02.
//

import Foundation
import BloomModel

extension URLRequest {
  static let baseURL = URL(string: "https://bloom-api-5903aeb2ee43.herokuapp.com/")!
}

extension URLRequest {
  enum Auth {

    static func signIn(request: AuthenticationRequest) throws -> URLRequest {
      try URLRequest(url: baseURL.appendingPathComponent("v1/auth")).encoding(body: request)
    }
  }
}
