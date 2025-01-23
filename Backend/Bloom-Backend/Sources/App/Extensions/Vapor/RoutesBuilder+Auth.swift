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
}
