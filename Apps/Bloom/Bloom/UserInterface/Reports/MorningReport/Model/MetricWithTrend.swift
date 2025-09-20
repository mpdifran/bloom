//
//  MetricWithTrend.swift
//  Bloom
//
//  Created by Assistant on 2025-01-25.
//

import Foundation

struct MetricWithTrend: SendableNetworkModel {
  let value: String
  let trend: Trend?

  enum Trend: String, Codable, Sendable {
    case increasing
    case stable
    case decreasing
  }
}

extension MetricWithTrend {
  init(value: String) {
    self.value = value
    self.trend = nil
  }
}