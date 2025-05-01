//
//  WorkoutRoute.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-18.
//

import CoreLocation

public struct WorkoutRoute: Sendable, Equatable {
  public let locations: [CLLocation]

  public init(locations: [CLLocation]) {
    self.locations = locations
  }
}
