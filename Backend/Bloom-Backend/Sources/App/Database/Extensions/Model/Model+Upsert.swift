//
//  Model+Upsert.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Vapor
import Fluent

extension Model where IDValue: Hashable {

    static func findOrCreate(id: Self.IDValue, on db: Database) async throws -> Self {
        if let existing = try await Self.find(id, on: db).get() {
            return existing
        }
        let new = Self()
        new.id = id
        return new
    }

    func createOrUpdate(on db: Database) async throws {
        if self._$id.exists {
            try await update(on: db)
        } else {
            try await create(on: db)
        }
    }
}
