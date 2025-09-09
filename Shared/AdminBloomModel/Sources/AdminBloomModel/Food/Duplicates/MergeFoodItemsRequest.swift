//
//  MergeFoodItemsRequest.swift
//  AdminBloomModel
//
//  Created by Assistant on 2025-09-09.
//

import BloomModel
import Foundation

public struct MergeFoodItemsRequest: Codable, Sendable {
  public let primaryItemId: FoodItemIdentifier
  public let itemsToMerge: [FoodItemIdentifier]
  public let mergedItem: AdminFoodItemRecord
  public let deleteOthers: Bool
  
  public init(
    primaryItemId: FoodItemIdentifier,
    itemsToMerge: [FoodItemIdentifier],
    mergedItem: AdminFoodItemRecord,
    deleteOthers: Bool = true
  ) {
    self.primaryItemId = primaryItemId
    self.itemsToMerge = itemsToMerge
    self.mergedItem = mergedItem
    self.deleteOthers = deleteOthers
  }
}

public struct MergeFoodItemsResponse: Codable, Sendable, Hashable {
  public let mergedItem: AdminFoodItemRecord
  public let deletedCount: Int
  public let success: Bool
  
  public init(
    mergedItem: AdminFoodItemRecord,
    deletedCount: Int,
    success: Bool
  ) {
    self.mergedItem = mergedItem
    self.deletedCount = deletedCount
    self.success = success
  }
}