//
//  DateQuantitySample.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import Foundation
@preconcurrency import HealthKit

public struct DateQuantitySample: Identifiable, Hashable, Sendable {
  public var id: Int { hashValue }

  public let date: Date
  public let quantity: HKQuantity

  public init(date: Date, quantity: HKQuantity) {
    self.date = date
    self.quantity = quantity
  }
}
