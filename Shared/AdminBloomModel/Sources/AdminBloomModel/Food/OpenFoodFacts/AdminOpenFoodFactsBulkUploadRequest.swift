//
//  AdminOpenFoodFactsBulkUploadRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-09.
//

import Foundation

public struct AdminOpenFoodFactsBulkUploadRequest: Codable, Sendable {
  public let items: [AdminOpenFoodFactsBulkUploadItem]

  public init(items: [AdminOpenFoodFactsBulkUploadItem]) {
    self.items = items
  }
}
