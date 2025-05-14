import Vapor
import WebSocketKit
import NIOWebSocket
//import TelemetryDeck

// configures your application
public func configure(_ app: Application) async throws {

  // TelemetryDeck
  //    app.telemetryDeck.initialize(appID: "F1AC4445-7F73-4026-A19A-FF2250C34853")

  // Debug
  app.printEnvironmentInfo()

  // Redis
  try app.setupRedis()

  // Middleware

  // Routes
  app.routes.defaultMaxBodySize = "10mb"
  try routes(app)

  // Database
  try app.setupPostgres()
  allMigrations.forEach { app.migrations.add($0) }
  if app.environment == .development {
    try await app.autoMigrate()
  }

  // APNs
  try app.configureAPNs()
}
