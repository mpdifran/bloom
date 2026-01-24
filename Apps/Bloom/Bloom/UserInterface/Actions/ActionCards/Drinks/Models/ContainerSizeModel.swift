//
//  ContainerSizeModel.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import Foundation
import HealthKit
import BloomFoundation

struct ContainerSizeModel: Identifiable, Hashable, Codable, Sendable {
  let id: UUID
  var name: String
  var volumeML: Double
  var shapeType: ContainerShapeType
  let isSystemDefault: Bool

  init(
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

  var quantity: HKQuantity {
    HKQuantity(unit: .literUnit(with: .milli), doubleValue: volumeML)
  }

  @MainActor
  func displayValue(useMetric: Bool = true) -> String {
    if useMetric {
      if volumeML >= 1000 {
        return String(format: "%.1f L", volumeML / 1000)
      } else {
        return String(format: "%.0f mL", volumeML)
      }
    } else {
      let flOz = volumeML / 29.5735
      return String(format: "%.1f fl oz", flOz)
    }
  }
}

// MARK: - Default Containers

extension ContainerSizeModel {

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

extension ContainerSizeModel {

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
