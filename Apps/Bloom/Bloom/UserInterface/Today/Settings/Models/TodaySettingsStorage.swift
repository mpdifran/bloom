//
//  TodaySettingsStorage.swift
//  Bloom
//
//  Created by Assistant on 2025-08-27.
//

import SwiftUI

@propertyWrapper
struct TodaySettingsStorage: DynamicProperty {
  @State private var value: TodaySettings
  private let key: String
  private let userDefaults: UserDefaults
  
  init(wrappedValue: TodaySettings = TodaySettings(), _ key: String, store: UserDefaults = .standard) {
    self.key = key
    self.userDefaults = store
    
    // Load from UserDefaults if exists
    if let data = userDefaults.data(forKey: key),
       let decoded = try? JSONDecoder().decode(TodaySettings.self, from: data) {
      self._value = State(initialValue: decoded)
    } else {
      self._value = State(initialValue: wrappedValue)
    }
  }
  
  var wrappedValue: TodaySettings {
    get { value }
    nonmutating set {
      value = newValue
      // Save to UserDefaults
      if let encoded = try? JSONEncoder().encode(newValue) {
        userDefaults.set(encoded, forKey: key)
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