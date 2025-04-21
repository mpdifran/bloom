//
//  GoalTimePeriod.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-20.
//

import Foundation

public enum GoalTimePeriod: String, Identifiable, Codable, CaseIterable, Sendable {
  public var id: Self { self }

  case daily
  case weekly
  case monthly
  case yearly
}
