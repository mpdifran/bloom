//
//  QueryUserHealthDataArguments.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Foundation
import BloomModel

struct QueryUserHealthDataArguments: Codable, Equatable, Sendable {
  public let startDate: Date
  public let endDate: Date
  public let dataType: SocketMessage.QueryDataType
}
