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

  public init(
    email: String?,
    givenName: String?,
    familyName: String?
  ) {
    self.email = email
    self.givenName = givenName
    self.familyName = familyName
  }
}
