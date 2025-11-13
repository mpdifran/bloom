//
//  Request+BiologicalAge.swift
//  Bloom-Backend
//
//  Created by Claude Code
//

import Vapor

extension Request {

  var biologicalAgeJobManager: BiologicalAgeJobManager {
    application.biologicalAgeJobManager
  }
}
