import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.printEnvironmentInfo()

//    app.http.client.configuration.decompression = .enabled(limit: .ratio(10))

    // Lifecycle
    app.lifecycle.use(DefaultLifecycleHandler())

    // Routes
    app.routes.defaultMaxBodySize = "10mb"
    try routes(app)

    // Database
    try app.setupPostgres()

    // Migrations
    allMigrations.forEach { app.migrations.add($0) }
}

private struct DefaultLifecycleHandler: LifecycleHandler {

    func didBootAsync(_ application: Application) async throws {
        let privateDirectory = application.directory.workingDirectory + "Private/Food/"
        try await application.fileio.createDirectory(
            path: privateDirectory,
            withIntermediateDirectories: true,
            mode: 755
        )
    }
}
