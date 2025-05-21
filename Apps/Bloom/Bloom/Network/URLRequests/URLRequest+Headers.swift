//
//  URLRequest+Headers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-02.
//

import Foundation
import BloomModel

extension URLRequest {

  func settingBloomHeaders() async -> URLRequest {
    var request = self

    if let authToken = await UserController.shared.authToken {
      request.add(header: .authorizationBearer(authToken))
    }

    return request
  }

  func settingAPIVersionHeader(version: String) -> URLRequest {
    var request = self
    request.add(header: .apiVersion(version))
    return request
  }
}

extension URLRequest {
  enum Header {
    case authorizationBearer(AuthToken)
    case contentTypeJSON
    case apiVersion(String)
  }

  enum HeaderKey: String {
    case authorization = "Authorization"
    case contentType = "Content-Type"
    case apiVersion = "X-Bloom-API-Version"
  }

  mutating func add(header: Header) {
    switch header {
    case .authorizationBearer(let token):
      addValue("Bearer \(token.value)", for: .authorization)
    case .contentTypeJSON:
      addValue("application/json", for: .contentType)
    case .apiVersion(let version):
      addValue(version, for: .apiVersion)
    }
  }

  func value(for headerKey: HeaderKey) -> String? {
    value(forHTTPHeaderField: headerKey.rawValue)
  }
}

private extension URLRequest {

  mutating func addValue(_ value: String, for headerKey: HeaderKey) {
    addValue(value, forHTTPHeaderField: headerKey.rawValue)
  }
}
