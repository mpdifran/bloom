//
//  SecurityHeadersMiddleware.swift
//  Bloom-Backend
//
//  Adds defense-in-depth security response headers. Heroku's router terminates
//  TLS but does not add these, so we set them here.
//

import Vapor

struct SecurityHeadersMiddleware: AsyncMiddleware {

  func respond(
    to request: Request,
    chainingTo next: any AsyncResponder
  ) async throws -> Response {
    let response = try await next.respond(to: request)

    response.headers.replaceOrAdd(name: "X-Content-Type-Options", value: "nosniff")
    response.headers.replaceOrAdd(name: "X-Frame-Options", value: "DENY")
    response.headers.replaceOrAdd(
      name: "Strict-Transport-Security",
      value: "max-age=31536000; includeSubDomains"
    )
    response.headers.replaceOrAdd(name: "Referrer-Policy", value: "no-referrer")

    return response
  }
}
