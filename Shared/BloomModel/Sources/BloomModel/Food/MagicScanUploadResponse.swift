//
//  MagicScanUploadResponse.swift
//  bloom-model
//
//  Created by Claude on 2025-10-25.
//

import Foundation

public struct MagicScanUploadResponse: Codable, Sendable {
  public let processingIdentifier: AIFoodProcessingIdentifier
  public let status: String

  public init(
    processingIdentifier: AIFoodProcessingIdentifier,
    status: String
  ) {
    self.processingIdentifier = processingIdentifier
    self.status = status
  }
}
