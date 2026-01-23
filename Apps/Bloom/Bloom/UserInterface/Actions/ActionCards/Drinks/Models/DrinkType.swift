//
//  DrinkType.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI

// MARK: - DrinkCategory

enum DrinkCategory: String, CaseIterable, Codable, Sendable {
  case water = "Water"
  case coffee = "Coffee"
  case tea = "Tea"
  case milk = "Milk"
  case soft = "Soft"
  case alcohol = "Alcohol"
  case custom = "Custom"

  var displayName: String { rawValue }
}

// MARK: - ContainerShapeType

enum ContainerShapeType: String, Codable, Sendable, CaseIterable {
  case waterBottle
  case coffeeCup
  case espressoCup
  case teaCup
  case glass
  case beerGlass
  case wineGlass
  case shaker
}

// MARK: - DrinkType

struct DrinkType: Identifiable, Hashable, Codable, Sendable {
  let id: UUID
  let name: String
  let category: DrinkCategory
  let symbolName: String
  let colorHex: String
  let hydrationCoefficient: Double
  let containerShapeType: ContainerShapeType
  let isCustom: Bool
  let subTypes: [DrinkType]?
  let abv: Double?
  let caffeinePer250ML: Double?

  init(
    id: UUID = UUID(),
    name: String,
    category: DrinkCategory,
    symbolName: String,
    colorHex: String,
    hydrationCoefficient: Double,
    containerShapeType: ContainerShapeType,
    isCustom: Bool = false,
    subTypes: [DrinkType]? = nil,
    abv: Double? = nil,
    caffeinePer250ML: Double? = nil
  ) {
    self.id = id
    self.name = name
    self.category = category
    self.symbolName = symbolName
    self.colorHex = colorHex
    self.hydrationCoefficient = hydrationCoefficient
    self.containerShapeType = containerShapeType
    self.isCustom = isCustom
    self.subTypes = subTypes
    self.abv = abv
    self.caffeinePer250ML = caffeinePer250ML
  }

  var hasSubTypes: Bool {
    subTypes?.isEmpty == false
  }

  func caffeineContent(forML amount: Double) -> Double? {
    guard let caffeine = caffeinePer250ML, caffeine > 0 else { return nil }
    return (amount / 250.0) * caffeine
  }

  var liquidColor: Color {
    Color(hex: colorHex) ?? .blue
  }
}

// MARK: - Default Drinks

extension DrinkType {

  // MARK: Beer Sub-Types

  static let beerSubTypes: [DrinkType] = [
    DrinkType(
      name: "Light Beer",
      category: .alcohol,
      symbolName: "mug.fill",
      colorHex: "#C9A227",
      hydrationCoefficient: 0.55,
      containerShapeType: .beerGlass,
      abv: 4.0
    ),
    DrinkType(
      name: "Lager",
      category: .alcohol,
      symbolName: "mug.fill",
      colorHex: "#B8860B",
      hydrationCoefficient: 0.50,
      containerShapeType: .beerGlass,
      abv: 5.0
    ),
    DrinkType(
      name: "IPA",
      category: .alcohol,
      symbolName: "mug.fill",
      colorHex: "#CC5500",
      hydrationCoefficient: 0.42,
      containerShapeType: .beerGlass,
      abv: 6.5
    ),
    DrinkType(
      name: "Stout",
      category: .alcohol,
      symbolName: "mug.fill",
      colorHex: "#5C4033",
      hydrationCoefficient: 0.45,
      containerShapeType: .beerGlass,
      abv: 6.0
    )
  ]

  // MARK: Wine Sub-Types

  static let wineSubTypes: [DrinkType] = [
    DrinkType(
      name: "Sparkling",
      category: .alcohol,
      symbolName: "wineglass.fill",
      colorHex: "#D4AF37",
      hydrationCoefficient: 0.35,
      containerShapeType: .wineGlass,
      abv: 12.0
    ),
    DrinkType(
      name: "White Wine",
      category: .alcohol,
      symbolName: "wineglass.fill",
      colorHex: "#C5B358",
      hydrationCoefficient: 0.30,
      containerShapeType: .wineGlass,
      abv: 12.0
    ),
    DrinkType(
      name: "Rosé",
      category: .alcohol,
      symbolName: "wineglass.fill",
      colorHex: "#E8909C",
      hydrationCoefficient: 0.30,
      containerShapeType: .wineGlass,
      abv: 12.0
    ),
    DrinkType(
      name: "Red Wine",
      category: .alcohol,
      symbolName: "wineglass.fill",
      colorHex: "#8B3A3A",
      hydrationCoefficient: 0.25,
      containerShapeType: .wineGlass,
      abv: 13.5
    )
  ]

  // MARK: Default Drinks Catalog

  static let defaultDrinks: [DrinkType] = [
    // Water
    DrinkType(
      name: "Water",
      category: .water,
      symbolName: "waterbottle.fill",
      colorHex: "#4A90D9",
      hydrationCoefficient: 1.0,
      containerShapeType: .waterBottle
    ),

    // Coffee
    DrinkType(
      name: "Coffee",
      category: .coffee,
      symbolName: "cup.and.saucer.fill",
      colorHex: "#6F4E37",
      hydrationCoefficient: 0.85,
      containerShapeType: .coffeeCup,
      caffeinePer250ML: 95
    ),

    // Tea
    DrinkType(
      name: "Tea",
      category: .tea,
      symbolName: "leaf.fill",
      colorHex: "#CD853F",
      hydrationCoefficient: 0.92,
      containerShapeType: .teaCup,
      caffeinePer250ML: 35
    ),

    // Soft Drinks
    DrinkType(
      name: "Juice",
      category: .soft,
      symbolName: "carrot.fill",
      colorHex: "#FFA500",
      hydrationCoefficient: 0.85,
      containerShapeType: .glass
    ),
    DrinkType(
      name: "Soda",
      category: .soft,
      symbolName: "bubbles.and.sparkles",
      colorHex: "#8B4513",
      hydrationCoefficient: 0.85,
      containerShapeType: .glass,
      caffeinePer250ML: 34
    ),

    // Alcohol (Parent categories with sub-types)
    DrinkType(
      name: "Beer",
      category: .alcohol,
      symbolName: "mug.fill",
      colorHex: "#DAA520",
      hydrationCoefficient: 0.50,
      containerShapeType: .beerGlass,
      subTypes: beerSubTypes
    ),
    DrinkType(
      name: "Wine",
      category: .alcohol,
      symbolName: "wineglass.fill",
      colorHex: "#722F37",
      hydrationCoefficient: 0.30,
      containerShapeType: .wineGlass,
      subTypes: wineSubTypes
    )
  ]
}

// MARK: - Color Extension

private extension Color {
  init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    guard hexSanitized.count == 6 else { return nil }

    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)

    let red = Double((rgb & 0xFF0000) >> 16) / 255.0
    let green = Double((rgb & 0x00FF00) >> 8) / 255.0
    let blue = Double(rgb & 0x0000FF) / 255.0

    self.init(red: red, green: green, blue: blue)
  }
}
