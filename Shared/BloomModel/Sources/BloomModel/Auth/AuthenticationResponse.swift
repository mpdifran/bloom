//
//  AuthenticationResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-01.
//

import Foundation

public struct AuthenticationResponse: Codable {
    public let authToken: AuthToken

    public init(authToken: AuthToken) {
        self.authToken = authToken
    }
}
