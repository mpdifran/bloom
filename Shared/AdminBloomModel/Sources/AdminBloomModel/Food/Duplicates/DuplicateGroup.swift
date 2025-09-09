//
//  DuplicateGroup.swift
//  AdminBloomModel
//
//  Created by Assistant on 2025-09-09.
//

import Foundation

public struct DuplicateGroup: Codable, Sendable, Identifiable, Hashable {
  public let id: String
  public let primaryItem: AdminFoodItemRecord
  public let duplicates: [DuplicateCandidate]
  public let totalCount: Int
  
  public init(
    id: String,
    primaryItem: AdminFoodItemRecord,
    duplicates: [DuplicateCandidate],
    totalCount: Int
  ) {
    self.id = id
    self.primaryItem = primaryItem
    self.duplicates = duplicates
    self.totalCount = totalCount
  }
}

public struct DuplicateCandidate: Codable, Sendable, Identifiable, Hashable {
  public let id: String
  public let item: AdminFoodItemRecord
  public let similarityScore: Double
  public let matchTypes: [MatchType]
  
  public init(
    item: AdminFoodItemRecord,
    similarityScore: Double,
    matchTypes: [MatchType]
  ) {
    self.id = item.id.value
    self.item = item
    self.similarityScore = similarityScore
    self.matchTypes = matchTypes
  }
}

public enum MatchType: String, Codable, Sendable, CaseIterable, Hashable {
  case exactBarcode = "exact_barcode"
  case similarName = "similar_name"
  case similarBrand = "similar_brand"
  case similarNutrition = "similar_nutrition"
  case combined = "combined"
  
  public var displayName: String {
    switch self {
    case .exactBarcode:
      return "Exact Barcode"
    case .similarName:
      return "Similar Name"
    case .similarBrand:
      return "Similar Brand"
    case .similarNutrition:
      return "Similar Nutrition"
    case .combined:
      return "Combined Match"
    }
  }
}