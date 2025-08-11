//
//  SideEffectType.swift
//  DataContainer
//
//  Created by Assistant on 2025-08-09.
//

import Foundation

/// Defines the types of side effects that can be executed when a reminder is completed
public enum SideEffectType: String, Codable, CaseIterable, Sendable {
  case logFood = "log_food"
  case logWater = "log_water"
  
  public var displayName: String {
    switch self {
    case .logFood:
      return "Log Food"
    case .logWater:
      return "Log Water"
    }
  }
}