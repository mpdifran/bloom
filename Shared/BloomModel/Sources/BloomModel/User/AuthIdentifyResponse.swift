//
//  AuthIdentifyResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-04.
//

import Foundation

public struct AuthIdentifyResponse: Codable, Hashable, Sendable {
  public let email: String?
  public let givenName: String?
  public let familyName: String?
  /// The Sign in with Apple identifier the current developer team knows this user by.
  ///
  /// After the team migration a device may still hold the identifier issued by the old team, which
  /// Apple no longer resolves. The server sends the migrated identifier so the client can replace
  /// what it has. Nil when there is nothing to replace - the account was created after the transfer,
  /// or it was never migrated.
  public let appleUserIdentifier: String?

  public init(
    email: String?,
    givenName: String?,
    familyName: String?,
    appleUserIdentifier: String? = nil
  ) {
    self.email = email
    self.givenName = givenName
    self.familyName = familyName
    self.appleUserIdentifier = appleUserIdentifier
  }
}
