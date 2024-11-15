//
//  EnablePgTrgmMigration.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Vapor
import Fluent
import SQLKit

struct EnablePgTrgmMigration: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sqlDatabase = database as? SQLDatabase else {
            fatalError("This migration requires an SQL database.")
        }

        return try await sqlDatabase.raw(
            "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
        ).run()
    }

    func revert(on database: Database) async throws {
        // No-op. Extensions generally don't need to be removed on revert.
    }
}
