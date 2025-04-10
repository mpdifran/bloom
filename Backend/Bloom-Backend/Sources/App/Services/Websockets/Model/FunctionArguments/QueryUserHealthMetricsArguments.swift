//
//  QueryUserHealthMetricsArguments.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-10.
//

import Foundation
import BloomModel

struct QueryUserHealthMetricsArguments: Codable, Equatable, Sendable {
  public let startDate: Date
  public let endDate: Date
  public let healthMetric: SuggestedGoal.Metric
}
