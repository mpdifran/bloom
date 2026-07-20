import Vapor
import WebSocketKit
import NIOWebSocket
//import TelemetryDeck

// Lifecycle handler for shutting down resources
struct ShutdownHandler: LifecycleHandler {
    let shutdownAWSClient: @Sendable () -> Void

    func shutdown(_ application: Application) {
        shutdownAWSClient()
    }
}

// configures your application
public func configure(_ app: Application) async throws {

  // TelemetryDeck
  //    app.telemetryDeck.initialize(appID: "F1AC4445-7F73-4026-A19A-FF2250C34853")

  // Debug
  app.printEnvironmentInfo()

  // Redis
  try app.setupRedis()

  // Middleware
  app.middleware.use(SecurityHeadersMiddleware())
  // Generous global rate limit: stops runaway abuse of the paid-AI endpoints
  // without throttling normal use. Tighten if abuse is observed.
  app.middleware.use(RateLimitMiddleware(limit: 240, window: 60))
  app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

  // Routes
  app.routes.defaultMaxBodySize = "10mb"
  try routes(app)

  // Database
  try app.setupPostgres()
  allMigrations.forEach { app.migrations.add($0) }
  if app.environment == .development {
    try await app.autoMigrate()
  }

  // Commands
  app.asyncCommands.use(SIWAMigrationCommand(), as: "siwa-migrate")

  // APNs
  try app.configureAPNs()
  
  // Cron jobs
  try app.configureCronJobs()
  
  // Shutdown handlers
  app.lifecycle.use(
    ShutdownHandler(shutdownAWSClient: app.shutdownAWSClient)
  )
}
