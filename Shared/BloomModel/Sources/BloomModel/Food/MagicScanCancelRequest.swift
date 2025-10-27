//
//  MagicScanCancelRequest.swift
//  bloom-model
//
//  Created by Claude on 2025-10-27.
//

import Foundation

public struct MagicScanCancelRequest: Codable, Sendable {
  public let processingIdentifier: AIFoodProcessingIdentifier

  public init(processingIdentifier: AIFoodProcessingIdentifier) {
    self.processingIdentifier = processingIdentifier
  }
}
