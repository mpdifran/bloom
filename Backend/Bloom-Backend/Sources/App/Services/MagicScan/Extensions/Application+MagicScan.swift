//
//  Application+MagicScan.swift
//  Bloom-Backend
//
//  Created by Claude on 2025-10-25.
//

import Vapor

extension Application {

  private struct MagicScanJobManagerKey: StorageKey {
    typealias Value = MagicScanJobManager
  }

  var magicScanJobManager: MagicScanJobManager {
    if let manager = storage[MagicScanJobManagerKey.self] {
      return manager
    }

    let manager = MagicScanJobManager(
      redis: redis,
      logger: logger
    )

    storage[MagicScanJobManagerKey.self] = manager
    return manager
  }
}
