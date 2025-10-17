//
//  URLRequest+Encoding.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-02.
//

import Foundation
import BloomModel

public extension URLRequest {

  mutating func encode<T>(body: T) throws where T: Encodable {
    method = .post
    add(header: .contentTypeJSON)
    httpBody = try JSONEncoder.bloomModel.encode(body)
  }

  func encoding<T>(body: T) throws -> URLRequest where T: Encodable {
    var request = self
    try request.encode(body: body)
    return request
  }
}
