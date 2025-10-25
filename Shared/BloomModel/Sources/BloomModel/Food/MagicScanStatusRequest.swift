//
//  MagicScanStatusRequest.swift
//  bloom-model
//
//  Created by Claude on 2025-10-25.
//

import Foundation

public struct MagicScanStatusRequest: Codable, Sendable {
  public let processingIdentifiers: [AIFoodProcessingIdentifier]

  public init(processingIdentifiers: [AIFoodProcessingIdentifier]) {
    self.processingIdentifiers = processingIdentifiers
  }
}
