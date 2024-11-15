//
//  Model+Upsert.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Vapor
import Fluent

extension Model where IDValue: Hashable {

    /// Performs an upsert operation on the database.
    /// - Parameters:
    ///   - db: The database instance to use for the operation.
    ///   - model: The model to upsert
    /// - Returns: The saved model instance (either newly created or updated).
    @discardableResult
    static func upsert(
        on db: Database,
        model: Self
    ) async throws -> Self {
        if var existing = try await Self.find(model.id, on: db) {
            // Automatically copy properties from `model` to `existing`
            let newMirror = Mirror(reflecting: model)
            for case let (label?, value) in newMirror.children {
                if let keyPath = keyPath(for: label) {
                    existing[keyPath: keyPath] = value
                }
            }

            try await existing.update(on: db)
            return existing
        } else {
            try await model.create(on: db)
            return model
        }
    }

    /// Converts a property name into a `KeyPath` for this model.
    /// - Parameter name: The name of the property.
    /// - Returns: A `WritableKeyPath` corresponding to the property, if it exists.
    private static func keyPath(for name: String) -> WritableKeyPath<Self, Any?>? {
        // Use Swift's reflection to find a matching property.
        let mirror = Mirror(reflecting: Self.init())
        for case let (propertyName?, keyPath) in mirror.children {
            if propertyName == name {
                return keyPath as? WritableKeyPath<Self, Any?>
            }
        }
        return nil
    }
}
