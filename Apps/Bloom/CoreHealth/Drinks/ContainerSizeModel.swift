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
        return String(format: "%.1f L", convertedValue / 1000)
      } else {
        return String(format: "%.0f mL", convertedValue)
      }
    } else if liquidUnit == .fluidOunceUS() {
      if convertedValue < 10 {
        return String(format: "%.1f fl oz", convertedValue)
      } else {
        return String(format: "%.0f fl oz", convertedValue)
      }
    } else if liquidUnit == .liter() {
      return String(format: "%.2f L", convertedValue)
    } else {
      return String(format: "%.1f %@", convertedValue, liquidUnit.sensibleUnitString)
    }
  }
}

// MARK: - Default Containers

public extension ContainerSizeModel {

  static let defaults: [ContainerSizeModel] = [
    ContainerSizeModel(name: "Shot", volumeML: 30, shapeType: .shotGlass, isSystemDefault: true),
    ContainerSizeModel(name: "Small Glass", volumeML: 150, shapeType: .glass, isSystemDefault: true),
    ContainerSizeModel(name: "Glass", volumeML: 250, shapeType: .glass, isSystemDefault: true),
    ContainerSizeModel(name: "Large Glass", volumeML: 350, shapeType: .glass, isSystemDefault: true),
    ContainerSizeModel(name: "Can", volumeML: 355, shapeType: .can, isSystemDefault: true),
    ContainerSizeModel(name: "Bottle", volumeML: 500, shapeType: .waterBottle, isSystemDefault: true),
    ContainerSizeModel(name: "Pint", volumeML: 473, shapeType: .beerGlass, isSystemDefault: true),
    ContainerSizeModel(name: "Large Bottle", volumeML: 750, shapeType: .waterBottle, isSystemDefault: true),
    ContainerSizeModel(name: "Liter", volumeML: 1000, shapeType: .waterBottle, isSystemDefault: true)
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
