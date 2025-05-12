import Vapor
import WebSocketKit
import NIOWebSocket
//import TelemetryDeck

// configures your application
public func configure(_ app: Application) async throws {

  // TelemetryDeck
  //    app.telemetryDeck.initialize(appID: "F1AC4445-7F73-4026-A19A-FF2250C34853")

  app.logger.info("1")

  // Debug
  app.printEnvironmentInfo()

  app.logger.info("2")

  // Redis
  try app.setupRedis()

  app.logger.info("3")

  // Middleware

  // Routes
  app.routes.defaultMaxBodySize = "10mb"
  try routes(app)

  app.logger.info("4")

  // Database
  try app.setupPostgres()
  allMigrations.forEach { app.migrations.add($0) }
  try await app.autoMigrate() // Perform migration

  app.logger.info("5")

  // APNs
  try app.configureAPNs()

  app.logger.info("6")
}
