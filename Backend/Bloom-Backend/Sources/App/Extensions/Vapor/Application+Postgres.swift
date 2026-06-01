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
import NIOSSL

extension Application {

  func setupPostgres() throws {
    if let postgresURL = postgresURL {
      logger.info("Setting up Postgres via URL")
      
      // Parse the DATABASE_URL to handle SSL requirements
      guard let urlComponents = URLComponents(url: postgresURL, resolvingAgainstBaseURL: false),
            let host = urlComponents.host,
            let user = urlComponents.user,
            let password = urlComponents.password,
            let database = urlComponents.path.split(separator: "/").last.map(String.init) else {
        throw Abort(.internalServerError, reason: "Invalid DATABASE_URL format")
      }
      
      let port = urlComponents.port ?? 5432
      
      // Check if this is a Heroku database (they require SSL)
      let requiresSSL = host.contains("amazonaws.com") || host.contains("heroku")
      
      let tls: PostgresConnection.Configuration.TLS
      if requiresSSL {
        logger.info("Detected Heroku database, enabling SSL")
        // Create SSL context with no certificate verification for Heroku
        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.certificateVerification = .none
        let sslContext = try NIOSSLContext(configuration: tlsConfig)
        tls = .require(sslContext)
      } else {
        tls = .disable
      }
      
      let postgresConfig = SQLPostgresConfiguration(
        hostname: host,
        port: port,
        username: user,
        password: password,
        database: database,
        tls: tls
      )
      
      databases.use(
        .postgres(configuration: postgresConfig),
        as: .psql
      )
    } else {
      logger.info("Setting up Postgres via localhost")
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
            password: localhostPassword ?? "",
            database: databaseName,
            tls: .disable
          )
        ),
        as: .psql
      )
    }
  }
}
