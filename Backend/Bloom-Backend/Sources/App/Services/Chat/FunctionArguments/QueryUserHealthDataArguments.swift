//
//  QueryUserHealthDataArguments.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Foundation
import BloomModel

struct QueryUserHealthDataArguments: Codable, Equatable, Sendable {
  let queries: [Query]
}

extension QueryUserHealthDataArguments {
  struct Query: Codable, Equatable, Sendable {
    let startDate: Date
    let endDate: Date
    let dataType: SocketMessage.QueryDataType
  }
}
