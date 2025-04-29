//
//  SocketMessage+ToolCall.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-27.
//

import Foundation

public extension SocketMessage {
  struct ToolCallsRequest: Codable, Equatable, Sendable {
    public let runID: String
    public let toolCalls: [ToolCallWrapper]

    public init(runID: String, toolCalls: [ToolCallWrapper]) {
      self.runID = runID
      self.toolCalls = toolCalls
    }
  }
}

public extension SocketMessage {
  struct ToolCallWrapper: Codable, Equatable, Sendable {
    public let toolCallID: String
    public let kind: Kind

    public init(toolCallID: String, kind: Kind) {
      self.toolCallID = toolCallID
      self.kind = kind
    }
  }
}

public extension SocketMessage.ToolCallWrapper {
  enum Kind: Codable, Equatable, Sendable {
    case query(SocketMessage.Query)
    case newGoals([SocketMessage.HealthMetricGoal])
    case detectedFood(SocketMessage.DetectedFood)
    case logWeight(SocketMessage.LogWeight)
    case logWater(SocketMessage.LogWaterConsumption)
    case logBloodPressure(SocketMessage.LogBloodPressure)
    case logBowelMovement(SocketMessage.LogBowelMovement)
    case createWorkout(SocketMessage.WorkoutTemplate)
  }
}

public extension SocketMessage {
  struct ToolCallsResponse: Codable, Equatable, Sendable {
    public let runID: String
    public let toolCallResults: [ToolCallResult]

    public init(
      runID: String,
      toolCallResults: [ToolCallResult]
    ) {
      self.runID = runID
      self.toolCallResults = toolCallResults
    }
  }
}

public extension SocketMessage {
  struct ToolCallResult: Codable, Equatable, Sendable {
    public let toolCallID: String
    public let data: String

    public init(toolCallID: String, data: String = "") {
      self.toolCallID = toolCallID
      self.data = data
    }
  }
}
