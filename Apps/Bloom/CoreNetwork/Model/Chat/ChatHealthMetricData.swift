//
//  ChatHealthMetricData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-10.
//

import Foundation

public struct ChatHealthMetricData: SendableNetworkModel {
  public let samples: [Sample]

  public init(samples: [Sample]) {
    self.samples = samples
  }
}

extension ChatHealthMetricData {
  public struct Sample: SendableNetworkModel {
    public let date: Date
    public let value: String

    public init(date: Date, value: String) {
      self.date = date
      self.value = value
    }
  }
}
