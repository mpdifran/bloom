//
//  DrinkType.swift
//  CoreHealth
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import BloomFoundation

// MARK: - DrinkCategory

public enum DrinkCategory: String, CaseIterable, Codable, Sendable {
  case water = "Water"
  case coffee = "Coffee"
  case tea = "Tea"
  case milk = "Milk"
  case soft = "Soft"
  case alcohol = "Alcohol"
  case custom = "Custom"

  public var displayName: String {
    switch self {
    case .water: String(localized: "Water", bundle: Bundle.coreHealth, comment: "Display name for drink category")
    case .coffee: String(localized: "Coffee", bundle: Bundle.coreHealth, comment: "Display name for drink category")
    case .tea: String(localized: "Tea", bundle: Bundle.coreHealth, comment: "Display name for drink category")
    case .milk: String(localized: "Milk", bundle: Bundle.coreHealth, comment: "Display name for drink category")
    case .soft: String(localized: "Soft", bundle: Bundle.coreHealth, comment: "Display name for drink category")
    case .alcohol: String(localized: "Alcohol", bundle: Bundle.coreHealth, comment: "Display name for drink category")
    case .custom: String(localized: "Custom", bundle: Bundle.coreHealth, comment: "Display name for drink category")
    }
  }
}

// MARK: - ContainerShapeType

public enum ContainerShapeType: String, Codable, Sendable, CaseIterable {
  case waterBottle
  case coffeeCup
  case espressoCup
  case teaCup
  case glass
  case beerGlass
  case wineGlass
  case shaker
  case can
  case mug
  case tumbler
  case shotGlass

  public var displayName: String {
    switch self {
    case .waterBottle: String(localized: "Water Bottle", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .coffeeCup: String(localized: "Coffee Cup", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .espressoCup: String(localized: "Espresso Cup", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .teaCup: String(localized: "Tea Cup", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .glass: String(localized: "Glass", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .beerGlass: String(localized: "Beer Glass", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .wineGlass: String(localized: "Wine Glass", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .shaker: String(localized: "Shaker", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .can: String(localized: "Can", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .mug: String(localized: "Mug", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .tumbler: String(localized: "Tumbler", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    case .shotGlass: String(localized: "Shot Glass", bundle: Bundle.coreHealth, comment: "Display name for container shape type")
    }
  }
}

// MARK: - DrinkType

public struct DrinkType: Identifiable, Hashable, Codable, Sendable {
  public let id: UUID
  public let name: String
  public let category: DrinkCategory
  public let symbolName: String
  public let colorHex: String
  public let hydrationCoefficient: Double
  public let containerShapeType: ContainerShapeType
  public let isCustom: Bool
  public let subTypes: [DrinkType]?
  public let abv: Double?
  public let caffeinePer250ML: Double?
  public let sugarPer250ML: Double?

  public init(
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
    caffeinePer250ML: Double? = nil,
    sugarPer250ML: Double? = nil
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
    self.sugarPer250ML = sugarPer250ML
  }

  public var hasSubTypes: Bool {
    subTypes?.isEmpty == false
  }

  public func caffeineContent(forML amount: Double) -> Double? {
    guard let caffeine = caffeinePer250ML, caffeine > 0 else { return nil }
    return (amount / 250.0) * caffeine
  }

  public func sugarContent(forML amount: Double) -> Double? {
    guard let sugar = sugarPer250ML, sugar > 0 else { return nil }
    return (amount / 250.0) * sugar
  }

  public var liquidColor: Color {
    Color(hex: colorHex) ?? .blue
  }
}

// MARK: - Default Drinks

public extension DrinkType {

  // MARK: Beer Sub-Types

  static let beerSubTypes: [DrinkType] = [
    DrinkType(
      name: String(localized: "Light Beer", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .alcohol,
      symbolName: "mug.fill",
      colorHex: "#C9A227",
      hydrationCoefficient: 0.55,
      containerShapeType: .beerGlass,
      abv: 4.0
    ),
    DrinkType(
      name: String(localized: "Lager", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .alcohol,
      symbolName: "mug.fill",
      colorHex: "#B8860B",
      hydrationCoefficient: 0.50,
      containerShapeType: .beerGlass,
      abv: 5.0
    ),
    DrinkType(
      name: String(localized: "IPA", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .alcohol,
      symbolName: "mug.fill",
      colorHex: "#CC5500",
      hydrationCoefficient: 0.42,
      containerShapeType: .beerGlass,
      abv: 6.5
    ),
    DrinkType(
      name: String(localized: "Stout", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
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
      name: String(localized: "Sparkling", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .alcohol,
      symbolName: "wineglass.fill",
      colorHex: "#D4AF37",
      hydrationCoefficient: 0.35,
      containerShapeType: .wineGlass,
      abv: 12.0
    ),
    DrinkType(
      name: String(localized: "White Wine", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .alcohol,
      symbolName: "wineglass.fill",
      colorHex: "#C5B358",
      hydrationCoefficient: 0.30,
      containerShapeType: .wineGlass,
      abv: 12.0
    ),
    DrinkType(
      name: String(localized: "Rosé", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .alcohol,
      symbolName: "wineglass.fill",
      colorHex: "#E8909C",
      hydrationCoefficient: 0.30,
      containerShapeType: .wineGlass,
      abv: 12.0
    ),
    DrinkType(
      name: String(localized: "Red Wine", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .alcohol,
      symbolName: "wineglass.fill",
      colorHex: "#8B3A3A",
      hydrationCoefficient: 0.25,
      containerShapeType: .wineGlass,
      abv: 13.5
    )
  ]

  // MARK: Default Drinks Catalog

  /// Referenced directly rather than looked up by name.
  ///
  /// `name` is localized, so `defaultDrinks.first { $0.name == "Beer" }` returns nil in every
  /// language but English - which crashed previews that force-unwrapped it.
  static let beer = DrinkType(
    name: String(localized: "Beer", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
    category: .alcohol,
    symbolName: "mug.fill",
    colorHex: "#DAA520",
    hydrationCoefficient: 0.50,
    containerShapeType: .beerGlass,
    subTypes: beerSubTypes
  )

  static let defaultDrinks: [DrinkType] = [
    // Water
    DrinkType(
      name: String(localized: "Water", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .water,
      symbolName: "waterbottle.fill",
      colorHex: "#4A90D9",
      hydrationCoefficient: 1.0,
      containerShapeType: .waterBottle
    ),

    // Coffee
    DrinkType(
      name: String(localized: "Coffee", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .coffee,
      symbolName: "cup.and.saucer.fill",
      colorHex: "#6F4E37",
      hydrationCoefficient: 0.85,
      containerShapeType: .coffeeCup,
      caffeinePer250ML: 95
    ),

    // Tea
    DrinkType(
      name: String(localized: "Tea", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .tea,
      symbolName: "leaf.fill",
      colorHex: "#CD853F",
      hydrationCoefficient: 0.92,
      containerShapeType: .teaCup,
      caffeinePer250ML: 35
    ),

    // Soft Drinks
    DrinkType(
      name: String(localized: "Soda", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .soft,
      symbolName: "bubbles.and.sparkles",
      colorHex: "#8B4513",
      hydrationCoefficient: 0.85,
      containerShapeType: .glass,
      caffeinePer250ML: 34,
      sugarPer250ML: 27
    ),

    // Alcohol (Parent categories with sub-types)
    beer,
    DrinkType(
      name: String(localized: "Wine", bundle: Bundle.coreHealth, comment: "Name of a built-in drink type"),
      category: .alcohol,
      symbolName: "wineglass.fill",
      colorHex: "#722F37",
      hydrationCoefficient: 0.30,
      containerShapeType: .wineGlass,
      subTypes: wineSubTypes
    )
  ]
}
