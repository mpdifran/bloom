//
//  DuplicateDetectionRequest.swift
//  AdminBloomModel
//
//  Created by Assistant on 2025-09-09.
//

import Foundation

public struct DuplicateGroupsRequest: Codable, Sendable {
  public let limit: Int?
  public let offset: Int?
  public let minimumDuplicates: Int?
  public let category: AdminFoodItemRecord.Category?
  public let state: AdminFoodItemRecord.State?
  
  public init(
    limit: Int? = 50,
    offset: Int? = 0,
    minimumDuplicates: Int? = 2,
    category: AdminFoodItemRecord.Category? = nil,
    state: AdminFoodItemRecord.State? = nil
  ) {
    self.limit = limit
    self.offset = offset
    self.minimumDuplicates = minimumDuplicates
    self.category = category
    self.state = state
  }
}

public struct DuplicateGroupsResponse: Codable, Sendable, Hashable {
  public let groups: [DuplicateGroup]
  public let totalGroups: Int
  public let totalDuplicates: Int
  
  public init(
    groups: [DuplicateGroup],
    totalGroups: Int,
    totalDuplicates: Int
  ) {
    self.groups = groups
    self.totalGroups = totalGroups
    self.totalDuplicates = totalDuplicates
  }
}

public struct ItemDuplicatesRequest: Codable, Sendable {
  public let similarityThreshold: Double?
  public let limit: Int?
  
  public init(
    similarityThreshold: Double? = 0.3,
    limit: Int? = 20
  ) {
    self.similarityThreshold = similarityThreshold
    self.limit = limit
  }
}

public struct ItemDuplicatesResponse: Codable, Sendable, Hashable {
  public let item: AdminFoodItemRecord
  public let duplicates: [DuplicateCandidate]
  
  public init(
    item: AdminFoodItemRecord,
    duplicates: [DuplicateCandidate]
  ) {
    self.item = item
    self.duplicates = duplicates
  }
}