//
//  AsyncStreamWrapper.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation

@propertyWrapper
public class AsyncStreamable<Value> where Value: Sendable {

  public var wrappedValue: Value {
    get { _wrappedValue }
    set {
      _wrappedValue = newValue
      subscriptions.values.forEach { $0.yield(newValue) }
    }
  }

  public func update(_ newValue: Value) {
    wrappedValue = newValue
  }

  public init(wrappedValue: Value) {
    self._wrappedValue = wrappedValue
  }

  private var _wrappedValue: Value
  private var subscriptions: [UUID: AsyncStream<Value>.Continuation] = [:]

  public var projectedValue: AsyncStream<Value> {
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
