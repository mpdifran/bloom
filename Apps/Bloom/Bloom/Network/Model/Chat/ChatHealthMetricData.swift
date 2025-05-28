//
//  ChatHealthMetricData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-10.
//

import Foundation

struct ChatHealthMetricData: SendableNetworkModel {
  let samples: [Sample]
}

extension ChatHealthMetricData {
  struct Sample: SendableNetworkModel {
    let date: Date
    let value: String
  }
}
