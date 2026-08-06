//
//  RoutesBuilder+Auth.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-23.
//

import Foundation
import Vapor
import Fluent

extension RoutesBuilder {

  func auth<Token: ModelTokenAuthenticatable>(using token: Token.Type, configure: (RoutesBuilder) throws -> ()) rethrows {
    try grouped(token.authenticator()).group(token.guardMiddleware(), configure: configure)
  }

  /// Admin authentication: token auth + guard, plus a live allowlist re-check on every request so a
  /// removed admin loses access immediately (admin tokens never expire). Use for all admin routes.
  func adminAuth(configure: (RoutesBuilder) throws -> ()) rethrows {
    try grouped(AdminUserToken.authenticator())
      .grouped(AdminUserToken.guardMiddleware())
      .group(AdminAllowlistMiddleware(), configure: configure)
  }
}
