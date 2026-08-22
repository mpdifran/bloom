//
//  ContainerSizeModel.swift
//  CoreHealth
//
//  Created by Claude on 2026-01-23.
//

import Foundation
import HealthKit
import BloomFoundation

public struct ContainerSizeModel: Identifiable, Hashable, Codable, Sendable {
  public let id: UUID
  public var name: String
  public var volumeML: Double
  public var shapeType: ContainerShapeType
  public let isSystemDefault: Bool

  public init(
    id: UUID = UUID(),
    name: String,
    volumeML: Double,
    shapeType: ContainerShapeType = .glass,
    isSystemDefault: Bool = false
  ) {
    self.id = id
    self.name = name
    self.volumeML = volumeML
    self.shapeType = shapeType
    self.isSystemDefault = isSystemDefault
  }

  public var quantity: HKQuantity {
    HKQuantity(unit: .literUnit(with: .milli), doubleValue: volumeML)
  }

  @MainActor
  public func displayValue(unit: HKUnit? = nil) -> String {
    let liquidUnit = unit ?? HealthUnitPreferences.shared.liquidVolumeUnit
    let mlQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: volumeML)
    let convertedValue = mlQuantity.doubleValue(for: liquidUnit)

    if liquidUnit == .literUnit(with: .milli) {
      if convertedValue >= 1000 {
        return "\((convertedValue / 1000).format(using: .oneDecimalPlace)) L"
      } else {
        return "\(convertedValue.format(using: .noDecimalPlaces)) mL"
      }
    } else if liquidUnit == .fluidOunceUS() {
      if convertedValue < 10 {
        return "\(convertedValue.format(using: .oneDecimalPlace)) fl oz"
      } else {
        return "\(convertedValue.format(using: .noDecimalPlaces)) fl oz"
      }
    } else if liquidUnit == .liter() {
      return "\(convertedValue.format(using: .twoDecimalPlaces)) L"
    } else {
      return "\(convertedValue.format(using: .oneDecimalPlace)) \(liquidUnit.sensibleUnitString)"
    }
  }
}

// MARK: - Default Containers

public extension ContainerSizeModel {

  static let defaults: [ContainerSizeModel] = [
    ContainerSizeModel(name: String(localized: "Shot", bundle: Bundle.coreHealth, comment: "Name of a built-in drink container size"), volumeML: 30, shapeType: .shotGlass, isSystemDefault: true),
    ContainerSizeModel(name: String(localized: "Small Glass", bundle: Bundle.coreHealth, comment: "Name of a built-in drink container size"), volumeML: 150, shapeType: .glass, isSystemDefault: true),
    ContainerSizeModel(name: String(localized: "Glass", bundle: Bundle.coreHealth, comment: "Name of a built-in drink container size"), volumeML: 250, shapeType: .glass, isSystemDefault: true),
    ContainerSizeModel(name: String(localized: "Large Glass", bundle: Bundle.coreHealth, comment: "Name of a built-in drink container size"), volumeML: 350, shapeType: .glass, isSystemDefault: true),
    ContainerSizeModel(name: String(localized: "Can", bundle: Bundle.coreHealth, comment: "Name of a built-in drink container size"), volumeML: 355, shapeType: .can, isSystemDefault: true),
    ContainerSizeModel(name: String(localized: "Bottle", bundle: Bundle.coreHealth, comment: "Name of a built-in drink container size"), volumeML: 500, shapeType: .waterBottle, isSystemDefault: true),
    ContainerSizeModel(name: String(localized: "Pint", bundle: Bundle.coreHealth, comment: "Name of a built-in drink container size"), volumeML: 473, shapeType: .beerGlass, isSystemDefault: true),
    ContainerSizeModel(name: String(localized: "Large Bottle", bundle: Bundle.coreHealth, comment: "Name of a built-in drink container size"), volumeML: 750, shapeType: .waterBottle, isSystemDefault: true),
    ContainerSizeModel(name: String(localized: "Liter", bundle: Bundle.coreHealth, comment: "Name of a built-in drink container size"), volumeML: 1000, shapeType: .waterBottle, isSystemDefault: true)
  ]
}

// MARK: - Storage

public extension ContainerSizeModel {

  private static let storageKey = "DrinkTracking.customContainers"

  static func loadAll() -> [ContainerSizeModel] {
    guard
      let data = UserDefaults.group.data(forKey: storageKey),
      let containers = try? JSONDecoder().decode([ContainerSizeModel].self, from: data)
    else {
      return defaults
    }
    return containers.isEmpty ? defaults : containers
  }

  static func save(_ containers: [ContainerSizeModel]) {
    guard let data = try? JSONEncoder().encode(containers) else { return }
    UserDefaults.group.set(data, forKey: storageKey)
  }

  static func resetToDefaults() {
    save(defaults)
  }
}
