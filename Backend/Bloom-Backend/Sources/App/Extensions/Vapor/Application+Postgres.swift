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
      let databaseName = switch environment {
      case .production:
        "bloom-food-db"
      default:
        "bloom-db-dev"
      }

      databases.use(
        .postgres(
          configuration: .init(
            hostname: "localhost",
            username: localhostUsername ?? "mpdifran",
            password: "",
            database: databaseName,
            tls: .disable
          )
        ),
        as: .psql
      )
    }
  }
}
