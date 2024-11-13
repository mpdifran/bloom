//
//  FoodItemRecord.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor
import Fluent

final class FoodItemRecord: Model, @unchecked Sendable {
    static let schema = "food_item_records"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Enum(key: "state")
    var state: State

    @Field(key: "brand_name")
    var brandName: String?

    @Field(key: "flavour")
    var flavour: String?

    @Field(key: "barcode")
    var barcode: String?

    @Field(key: "nutrition_label_image")
    var nutritionLabelImage: String?

    @Field(key: "packaging_image")
    var packagingImage: String?

    @Field(key: "ingredients")
    var ingredients: String?

    @Field(key: "calories")
    var calories: Double?

    @Field(key: "protein")
    var protien: Double?

    @Field(key: "carbohydrates")
    var carbohydrates: Double?

    @Field(key: "fat")
    var fat: Double?

    @Field(key: "serving_name")
    var servingName: String?

    @Field(key: "serving_value")
    var servingValue: Double?

    @Field(key: "serving_unit")
    var servingUnit: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.state = .unverified
    }
}

extension FoodItemRecord {
    enum State: String, Codable {
        case unverified
        case verified
    }
}
