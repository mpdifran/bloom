//
//  AuthIdentifyRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-04.
//

import Foundation

public struct AuthIdentifyRequest: Codable, Equatable, Sendable {
  public let appUserID: String
  public let appVersion: String

  public init(
    appUserID: String,
    appVersion: String
  ) {
    self.appUserID = appUserID
    self.appVersion = appVersion
  }
}
