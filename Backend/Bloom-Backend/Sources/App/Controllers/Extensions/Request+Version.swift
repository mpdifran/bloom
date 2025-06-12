//
//  Request+Version.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-29.
//

import Vapor

extension Request {

  var version: WebSocketService.Version {
    headers[.Header.version].first == "v1" ? WebSocketService.Version.v1 : .v2
  }
}
