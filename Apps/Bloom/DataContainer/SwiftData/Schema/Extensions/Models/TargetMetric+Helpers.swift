//
//  TargetMetric+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-01.
//

import Foundation

public extension TargetMetric {

  var measurementStyle: TargetMetric.MeasurementStyle {
    switch self {
    case .calories: .range
    default: .minimum
    }
  }
}
