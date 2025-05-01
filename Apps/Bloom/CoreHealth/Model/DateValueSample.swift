//
//  DateValueSample.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-04.
//

import Foundation

public struct DateValueSample: Identifiable, Hashable, Sendable, Codable {
  public var id: Int { hashValue }

  public let date: Date
  public let value: Double

  public init(date: Date, value: Double) {
    self.date = date
    self.value = value
  }
}

