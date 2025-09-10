//
//  FoodItemDuplicate.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-09-09.
//

import Foundation
import Vapor
import Fluent

final class FoodItemDuplicate: Model, @unchecked Sendable {
  static let schema = "food_item_duplicates"

  @ID(key: .id)
  var id: UUID?

  @Parent(key: "food_item_id")
  var foodItem: FoodItemRecord

  @Parent(key: "duplicate_food_item_id") 
  var duplicateFoodItem: FoodItemRecord

  @Field(key: "similarity_score")
  var similarityScore: Double

  @Field(key: "match_types")
  var matchTypes: String

  @Enum(key: "admin_status")
  var adminStatus: AdminStatus

  @Field(key: "admin_user_id")
  var adminUserID: String?

  @Field(key: "admin_decision_at")
  var adminDecisionAt: Date?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() { }

  init(
    foodItemID: String,
    duplicateFoodItemID: String,
    similarityScore: Double,
    matchTypes: String
  ) {
    self.$foodItem.id = foodItemID
    self.$duplicateFoodItem.id = duplicateFoodItemID
    self.similarityScore = similarityScore
    self.matchTypes = matchTypes
    self.adminStatus = .pending
  }
}

extension FoodItemDuplicate {
  enum AdminStatus: String, Codable, CaseIterable, FluentEnum {
    static let schema = "admin_status"

    case pending
    case markedDistinct = "marked_distinct"

    var name: String {
      switch self {
      case .pending:
        return "Pending Review"
      case .markedDistinct:
        return "Marked as Distinct"
      }
    }
  }
}
