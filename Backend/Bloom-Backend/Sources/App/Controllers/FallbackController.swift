//
//  FallbackController.swift
//  Bloom-Backend
//
//  Created by Claude Code on 2025-11-04.
//

import Vapor

struct FallbackController {
  let app: Application
}

extension FallbackController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    // Root path handler
    routes.get("", use: serveIndexPage)

    // Catch-all route for any other unhandled paths
    // This must be registered LAST in routes.swift to avoid catching API endpoints
    routes.get("**", use: serveIndexPage)
  }
}

private extension FallbackController {

  @Sendable
  func serveIndexPage(_ request: Request) async throws -> Response {
    let publicPath = app.directory.publicDirectory
    let indexPath = publicPath + "index.html"

    return try await request.fileio.asyncStreamFile(at: indexPath)
  }
}
