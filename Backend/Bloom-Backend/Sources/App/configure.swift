import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.printEnvironmentInfo()

    // Routes
    try routes(app)
}
