//
//  FoodItemAccuracyReport.swift
//  Bloom-Backend
//
//  Created by Haocen Jiang on 2025-02-03.
//


import Fluent
import Vapor

final class FoodItemAccuracyReport: Model, Content, @unchecked Sendable {
  static let schema = "food_item_accuracy_reports"
  
  @ID(custom: "id", generatedBy: .user)
  var id: String?
  
  @Parent(key: "food_item_record_id")
  var foodItemRecord: FoodItemRecord
  
  @Field(key: "accuracy_score")
  var accuracyScore: Double
  
  @OptionalField(key: "evaluation_notes")
  var evaluationNotes: String?
  
  @OptionalField(key: "recommendations")
  var recommendations: [String: String]?
  
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?
  
  init() { }
  
  init(
    id: String = UUID().uuidString,
    foodItemRecord: String,
    accuracyScore: Double,
    evaluationNotes: String? = nil,
    recommendations: [String: String]? = nil
  ) {
    self.id = id
    self.$foodItemRecord.id = foodItemRecord
    self.accuracyScore = accuracyScore
    self.evaluationNotes = evaluationNotes
    self.recommendations = recommendations
  }
}
