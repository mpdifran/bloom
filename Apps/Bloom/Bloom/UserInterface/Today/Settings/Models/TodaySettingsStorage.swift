//
//  TodaySettingsStorage.swift
//  Bloom
//
//  Created by Assistant on 2025-08-27.
//

import SwiftUI
import BloomUI

@propertyWrapper
struct TodaySettingsStorage: DynamicProperty {
  @AppStorage private var _storedData: Data
  private let defaultValue: TodaySettings
  
  init(wrappedValue: TodaySettings = TodaySettings(), _ key: String, store: UserDefaults = .standard) {
    self.defaultValue = wrappedValue
    
    // Create default encoded data
    let defaultData = (try? JSONEncoder().encode(wrappedValue)) ?? Data()
    
    // Initialize AppStorage with the key, default value, and store
    self.__storedData = AppStorage(wrappedValue: defaultData, key, store: store)
  }
  
  var wrappedValue: TodaySettings {
    get {
      // Try to decode from stored data, fallback to default
      if let decoded = try? JSONDecoder().decode(TodaySettings.self, from: _storedData) {
        return decoded
      }
      return defaultValue
    }
    nonmutating set {
      // Encode and store
      if let encoded = try? JSONEncoder().encode(newValue) {
        _storedData = encoded
      }
    }
  }
  
  var projectedValue: Binding<TodaySettings> {
    Binding(
      get: { wrappedValue },
      set: { wrappedValue = $0 }
    )
  }
}
