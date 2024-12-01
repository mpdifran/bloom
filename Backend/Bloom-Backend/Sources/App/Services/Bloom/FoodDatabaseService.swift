//
//  File.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Foundation
import Vapor
import Fluent
import SQLKit
import BloomModel

struct FoodDatabaseService { }

extension FoodDatabaseService {

    func searchFoods(
        request: Request,
        query: String,
        category: FoodItemRecord.Category,
        limit: Int
    ) async throws -> [FoodItem] {
        guard !query.isEmpty else { return [] }

        guard let sqlDatabase = request.db as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
        }

        let results = try await sqlDatabase.raw("""
            SELECT *,
                   GREATEST(
                       similarity(name, \(bind: query)) * 1.5,
                       similarity(brand_name, \(bind: query)),
                       similarity(flavour, \(bind: query)) * 0.8
                   ) AS rank
            FROM food_item_records
            WHERE (similarity(name, \(bind: query)) > 0.1
               OR similarity(brand_name, \(bind: query)) > 0.1
               OR similarity(flavour, \(bind: query)) > 0.1)
              AND category = \(bind: category.rawValue)::category
            ORDER BY rank DESC
            LIMIT \(bind: limit)
        """).all(decodingFluent: FoodItemRecord.self)

        // Map database records to your FoodItem model
        return results.compactMap { $0.asFoodItem() }
    }

    func searchFoods(request: Request, barcode: String) async throws -> [FoodItem] {
        guard !barcode.isEmpty else { return [] }

        guard let sqlDatabase = request.db as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
        }

        let results = try await sqlDatabase.raw("""
            SELECT *
            FROM food_item_records
            WHERE barcode = \(bind: barcode)
        """).all(decodingFluent: FoodItemRecord.self)

        // Map database records to your FoodItem model
        return results.compactMap { $0.asFoodItem() }
    }

  func getUnverifiedFoodItemRecords(
    request: Request,
    limit: Int
  ) async throws -> [AdminFoodItemRecord] {
    guard let sqlDatabase = request.db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }

    let results = try await sqlDatabase.raw("""
          SELECT *
          FROM food_item_records
          WHERE state = 'unverified'
          LIMIT \(bind: limit)
      """).all(decodingFluent: FoodItemRecord.self)

    // Map database records to admin FoodItemRecord model.
    return results.compactMap { $0.asAdminFoodItemRecord() }
  }
}
