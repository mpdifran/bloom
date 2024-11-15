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

    @Enum(key: "category")
    var category: Category

    @Field(key: "barcode")
    var barcode: String?

    @Field(key: "nutrition_label_image")
    var nutritionLabelImage: String?

    @Field(key: "packaging_image")
    var packagingImage: String?

    @Field(key: "ingredients")
    var ingredients: String?

    @Enum(key: "country")
    var country: Country

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

    init(
        id: UUID = UUID(),
        name: String,
        country: Country,
        category: Category = .generic
    ) {
        self.id = id
        self.name = name
        self.state = .unverified
        self.category = category
        self.country = country
    }
}

extension FoodItemRecord {
    enum State: String, Codable {
        case unverified
        case verified
    }

    enum Category: String, Codable {
        case generic
        case fastfood
        case restaurant
        case branded
    }

    enum Country: String, Codable {
        case canada
        case usa
    }
}
