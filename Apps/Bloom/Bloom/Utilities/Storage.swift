//
//  Storage.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-06.
//

import SwiftUI

@propertyWrapper
struct Storage<T> {
  private let key: String
  private let defaultValue: T
  private let store: UserDefaults

  init(key: String, defaultValue: T, store: UserDefaults = .group) {
    self.key = key
    self.defaultValue = defaultValue
    self.store = store
  }

  var wrappedValue: T {
    get {
      store.object(forKey: key) as? T ?? defaultValue
    }
    set {
      store.set(newValue, forKey: key)
    }
  }
}
