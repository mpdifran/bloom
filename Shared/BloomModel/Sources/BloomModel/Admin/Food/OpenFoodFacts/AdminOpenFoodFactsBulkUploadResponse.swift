//
//  AdminOpenFoodFactsBulkUploadResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-10.
//

import Foundation

public struct AdminOpenFoodFactsBulkUploadResponse: Codable, Sendable {
  public let insertedCount: Int

  public init(insertedCount: Int) {
    self.insertedCount = insertedCount
  }
}
