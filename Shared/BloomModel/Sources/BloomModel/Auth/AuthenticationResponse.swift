//
//  AuthenticationResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-01.
//

import Foundation

public struct AuthenticationResponse: Codable, Hashable, Sendable {
  public let authToken: AuthToken
  public let identity: AuthIdentifyResponse

  public init(
    authToken: AuthToken,
    identity: AuthIdentifyResponse
  ) {
    self.authToken = authToken
    self.identity = identity
  }
}
