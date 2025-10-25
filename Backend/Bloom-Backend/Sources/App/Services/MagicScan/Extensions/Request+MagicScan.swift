//
//  Request+MagicScan.swift
//  Bloom-Backend
//
//  Created by Claude on 2025-10-25.
//

import Vapor

extension Request {

  var magicScanJobManager: MagicScanJobManager {
    application.magicScanJobManager
  }
}
