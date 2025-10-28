//
//  MagicScanUploadRequest.swift
//  bloom-model
//
//  Created by Claude on 2025-10-25.
//

import Foundation

public struct MagicScanUploadRequest: Codable, Sendable {
  public let foodImage: ImageFile?
  public let contextText: String?
  public let processingIdentifier: AIFoodProcessingIdentifier

  public init(
    foodImage: ImageFile?,
    contextText: String?,
    processingIdentifier: AIFoodProcessingIdentifier
  ) {
    self.foodImage = foodImage
    self.contextText = contextText
    self.processingIdentifier = processingIdentifier
  }
}
