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
        return decoded
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
