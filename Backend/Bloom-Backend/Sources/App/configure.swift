import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.printEnvironmentInfo()

//    app.http.client.configuration.decompression = .enabled(limit: .ratio(10))

    // Routes
    try routes(app)
}
