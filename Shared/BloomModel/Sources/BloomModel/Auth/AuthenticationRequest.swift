//
//  File.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-01.
//

import Foundation

public struct AuthenticationRequest: Codable, Equatable, Sendable {
    public let userIdentifier: UserIdentifier
    public let identityToken: String
    public let authorizationCode: String

    public init(
        userIdentifier: UserIdentifier,
        identityToken: String,
        authorizationCode: String
    ) {
        self.userIdentifier = userIdentifier
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
    }
}
