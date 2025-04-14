//
//  RegisterUserPushNotificationTokenRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-14.
//

public struct RegisterUserPushNotificationTokenRequest: Codable {
  public let deviceToken: String

  public init(deviceToken: String) {
    self.deviceToken = deviceToken
  }
}
