//
//  FoodLogDateState.swift
//  CoreHealth
//
//  Created by Assistant on 2025-10-17.
//

import Foundation

public enum FoodLogDateState: Sendable {
  case inProgress(Double)
  case complete
  case exceeded
}
