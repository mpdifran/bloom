//
//  Application+Postgres.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor
import Fluent
import FluentPostgresDriver

extension Application {

    func setupPostgres() throws {
        if let postgresURL = postgresURL {
            let postgresConfig = try SQLPostgresConfiguration(url: postgresURL)
            databases.use(
                .postgres(
                    configuration: postgresConfig
                ),
                as: .psql
            )
        } else {
            databases.use(
                .postgres(
                    configuration: .init(
                        hostname: "localhost",
                        username: "welsh",
                        password: "",
                        database: "bloom-food-db",
                        tls: .disable
                    )
                ),
                as: .psql
            )
        }
    }
}
