//
//  MagicScanStatus.swift
//  BloomModel
//
//  Created by Claude on 2025-10-25.
//

import Foundation

public enum MagicScanStatus: String, Codable, Sendable {
  case pending
  case processing
  case completed
  case failed
}
