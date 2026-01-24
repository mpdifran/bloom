//
//  YouSettingsStorage.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import BloomUI

@propertyWrapper
struct YouSettingsStorage: DynamicProperty {
  @AppStorage private var _storedData: Data
  private let defaultValue: YouSettings

  init(wrappedValue: YouSettings = YouSettings(), _ key: String, store: UserDefaults = .standard) {
    self.defaultValue = wrappedValue

    let defaultData = (try? JSONEncoder().encode(wrappedValue)) ?? Data()

    self.__storedData = AppStorage(wrappedValue: defaultData, key, store: store)
  }

  var wrappedValue: YouSettings {
    get {
      if let decoded = try? JSONDecoder().decode(YouSettings.self, from: _storedData) {
        // Migrate: Add any new sections from defaultOrder that aren't in the stored order
        let defaultSections = YouSettings.defaultOrder
        let missingSections = defaultSections.filter { !decoded.sectionOrder.contains($0) }

        if missingSections.isEmpty {
          return decoded
        } else {
          // Append missing sections at the end
          var migrated = decoded
          migrated.sectionOrder.append(contentsOf: missingSections)
          return migrated
        }
      }
      return defaultValue
    }
    nonmutating set {
      if let encoded = try? JSONEncoder().encode(newValue) {
        _storedData = encoded
      }
    }
  }

  var projectedValue: Binding<YouSettings> {
    Binding(
      get: { wrappedValue },
      set: { wrappedValue = $0 }
    )
  }
}
