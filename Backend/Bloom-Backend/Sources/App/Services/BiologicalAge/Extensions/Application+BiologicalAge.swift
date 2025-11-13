//
//  Application+BiologicalAge.swift
//  Bloom-Backend
//
//  Created by Claude Code
//

import Vapor

extension Application {

  private struct BiologicalAgeJobManagerKey: StorageKey {
    typealias Value = BiologicalAgeJobManager
  }

  var biologicalAgeJobManager: BiologicalAgeJobManager {
    if let manager = storage[BiologicalAgeJobManagerKey.self] {
      return manager
    }

    let manager = BiologicalAgeJobManager(
      redis: redis,
      logger: logger
    )

    storage[BiologicalAgeJobManagerKey.self] = manager
    return manager
  }
}
