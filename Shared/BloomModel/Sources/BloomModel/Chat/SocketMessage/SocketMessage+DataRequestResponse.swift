//
//  SocketMessage+DataRequestResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Foundation

public extension SocketMessage {
  struct Query: Codable, Equatable, Sendable {
    public let id: String
    public let startDate: Date
    public let endDate: Date
    public let dataType: QueryDataType

    public init(
      id: String,
      startDate: Date,
      endDate: Date,
      dataType: QueryDataType
    ) {
      self.id = id
      self.startDate = startDate
      self.endDate = endDate
      self.dataType = dataType
    }
  }

  struct QueryData: Codable, Equatable, Sendable {
    public let id: String
    public let data: String

    public init(
      id: String,
      data: String
    ) {
      self.id = id
      self.data = data
    }
  }
}

public extension SocketMessage {
  struct DataQueryResponse: Codable, Equatable, Sendable {
    public let id: String
    public let queries: [Query]

    public init(
      id: String,
      queries: [Query]
    ) {
      self.id = id
      self.queries = queries
    }
  }

  struct DataQueryRequest: Codable, Equatable, Sendable {
    public let id: String
    public let queryData: [QueryData]

    public init(
      id: String,
      queryData: [QueryData]
    ) {
      self.id = id
      self.queryData = queryData
    }
  }
}

public extension SocketMessage {
  enum QueryDataType: String, Codable, Equatable, Sendable, CaseIterable {
    case foodLogs
    case nutrition
    case goals
    case activityLevel
    case bodyWeight
    case bowelMovements
    case heart
    case menstruation
    case sleep
    case stress
    case workouts
    case targetHeartRateZoneMinutes
  }
}
