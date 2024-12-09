//
//  AdminOpenFoodFactsBulkUploadItem.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-09.
//

import Foundation

public struct AdminOpenFoodFactsBulkUploadItem: Codable, Sendable {
  public let barcode: String
  public let countries: [String]
  public let ingredients: String?

  public init(barcode: String, countries: [String], ingredients: String?) {
    self.barcode = barcode
    self.countries = countries
    self.ingredients = ingredients
  }
}
