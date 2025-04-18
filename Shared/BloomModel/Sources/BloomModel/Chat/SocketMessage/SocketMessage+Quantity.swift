//
//  SocketMessage+Quantity.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-18.
//

import Foundation

public struct Quantity: Codable, Equatable, Sendable {
  public let value: Double
  public let unit: String

  public init(value: Double, unit: String) {
    self.value = value
    self.unit = unit
  }
}
