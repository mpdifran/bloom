//
//  CodableStorage.swift
//  Bloom
//
//  Created by Claude on 2025-12-09.
//

import Foundation

@propertyWrapper
public struct CodableStorage<T: Codable> {
  private let key: String
  private let defaultValue: T
  private let store: UserDefaults

  public init(key: String, defaultValue: T, store: UserDefaults = .group) {
    self.key = key
    self.defaultValue = defaultValue
    self.store = store
  }

  public var wrappedValue: T {
    get {
      guard let data = store.data(forKey: key) else { return defaultValue }
      return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }
    set {
      guard let data = try? JSONEncoder().encode(newValue) else { return }
      store.set(data, forKey: key)
    }
  }
}
