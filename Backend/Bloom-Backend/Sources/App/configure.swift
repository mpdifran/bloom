import Vapor
//import TelemetryDeck

// configures your application
public func configure(_ app: Application) async throws {

  // TelemetryDeck
  //    app.telemetryDeck.initialize(appID: "F1AC4445-7F73-4026-A19A-FF2250C34853")

  // Debug
  app.printEnvironmentInfo()

  // Middleware

  // Routes
  app.routes.defaultMaxBodySize = "10mb"
  try routes(app)

  // Database
  try app.setupPostgres()

  // Migrations
  allMigrations.forEach { app.migrations.add($0) }
}
