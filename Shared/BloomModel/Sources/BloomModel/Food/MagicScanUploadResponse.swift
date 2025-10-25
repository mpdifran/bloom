//
//  MagicScanUploadResponse.swift
//  bloom-model
//
//  Created by Claude on 2025-10-25.
//

import Foundation

public struct MagicScanUploadResponse: Codable, Sendable {
  public let processingIdentifier: AIFoodProcessingIdentifier
  public let status: MagicScanStatus

  public init(
    processingIdentifier: AIFoodProcessingIdentifier,
    status: MagicScanStatus
  ) {
    self.processingIdentifier = processingIdentifier
    self.status = status
  }
}
