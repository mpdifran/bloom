//
//  AsyncStreamWrapper.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation

@propertyWrapper
class AsyncStreamable<Value> {

    var wrappedValue: Value {
        didSet {
            subscriptions.values.forEach {
                $0.yield(wrappedValue)
            }
        }
    }

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    private var subscriptions: [UUID: AsyncStream<Value>.Continuation] = [:]

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
