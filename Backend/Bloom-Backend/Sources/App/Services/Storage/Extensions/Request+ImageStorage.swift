//
//  Request+ImageStorage.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-01.
//

import Vapor

extension Request {

  var imageStorage: ImageStorage {
    application.imageStorage
  }
}
