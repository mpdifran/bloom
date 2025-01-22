//
//  AsyncStreamable.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-01-22.
//

import Foundation

@propertyWrapper
class AsyncStreamable<Value> where Value: Sendable {

  var wrappedValue: Value {
    get { _wrappedValue }
    set {
      _wrappedValue = newValue
      subscriptions.values.forEach { $0.yield(newValue) }
    }
  }

  func update(_ newValue: Value) {
    wrappedValue = newValue
  }

  init(wrappedValue: Value) {
    self._wrappedValue = wrappedValue
  }

  private var _wrappedValue: Value
  private var subscriptions: [UUID : AsyncStream<Value>.Continuation] = [:]

  var projectedValue: AsyncStream<Value> {
    AsyncStream { continuation in
      let id = UUID()
      subscriptions[id] = continuation
      continuation.yield(wrappedValue)
      continuation.onTermination = { [weak self] _ in
        self?.subscriptions.removeValue(forKey: id)
      }
    }
  }
}
