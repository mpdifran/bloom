//
//  File.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-01.
//

import Foundation

public extension AuthenticationRequest {
  enum UserDetectionStatus: String, Codable, Equatable, Sendable {
    case unsupported
    case unknown
    case likelyReal
    case newCase
  }
}

public struct AuthenticationRequest: Codable, Equatable, Sendable {
  public let userIdentifier: UserIdentifier
  public let identityToken: String
  public let authorizationCode: String
  public let email: String?
  public let givenName: String?
  public let familyName: String?
  public let userDetectionStatus: UserDetectionStatus

  public init(
    userIdentifier: UserIdentifier,
    identityToken: String,
    authorizationCode: String,
    email: String?,
    givenName: String?,
    familyName: String?,
    userDetectionStatus: UserDetectionStatus
  ) {
    self.userIdentifier = userIdentifier
    self.identityToken = identityToken
    self.authorizationCode = authorizationCode
    self.email = email
    self.givenName = givenName
    self.familyName = familyName
    self.userDetectionStatus = userDetectionStatus
  }
}
