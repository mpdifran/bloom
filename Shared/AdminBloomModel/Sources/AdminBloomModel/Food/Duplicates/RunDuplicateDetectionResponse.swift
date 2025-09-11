//
//  RunDuplicateDetectionResponse.swift
//  AdminBloomModel
//
//  Created by Assistant on 2025-09-11.
//

import Foundation

public struct RunDuplicateDetectionResponse: Codable, Sendable {
  public let success: Bool
  public let message: String
  public let totalItems: Int
  public let processedItems: Int
  public let itemsWithDuplicates: Int
  
  public init(
    success: Bool,
    message: String,
    totalItems: Int,
    processedItems: Int,
    itemsWithDuplicates: Int
  ) {
    self.success = success
    self.message = message
    self.totalItems = totalItems
    self.processedItems = processedItems
    self.itemsWithDuplicates = itemsWithDuplicates
  }
}