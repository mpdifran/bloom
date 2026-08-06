//
//  AdminAllowlistMiddleware.swift
//  Bloom-Backend
//
//  Re-validates, on every authenticated admin request, that the admin's email is still on the
//  allowlist. Admin tokens never expire and `isValid` is always true, so without this the allowlist
//  would only be enforced at sign-in — removing an email from GARDENER_ADMIN_EMAIL_ALLOWLIST would
//  not revoke an existing admin session. Fails closed (an unset/empty allowlist rejects everyone).
//

import Vapor

struct AdminAllowlistMiddleware: AsyncMiddleware {

  func respond(
    to request: Request,
    chainingTo next: any AsyncResponder
  ) async throws -> Response {
    let admin = try request.auth.require(AdminUser.self)
    let allowlist = request.application.adminEmailAllowList()

    guard
      let email = admin.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
      allowlist.contains(email)
    else {
      throw Abort(.forbidden, reason: "Admin access has been revoked.")
    }

    return try await next.respond(to: request)
  }
}
