//
//  Application+Keys.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Vapor
import SignInWithApple
import JWT

extension Application {

    func printEnvironmentInfo() {
        logger.notice("Environment: \(environment.name)")

        if let _ = postgresURL {
            logger.notice("Postgres URL set")
        } else {
            logger.notice("Using local Postgres")
        }
    }
}

// MARK: - Sign in with Apple

extension Application {

    var appleTeamID: String {
        Environment.get("APPLE_TEAM_ID") ?? ""
    }

    var appBundleID: String {
        "com.lotus-labs.bloom"
    }

    var siwaJWKId: String {
        Environment.get("SIWA_JWK_ID") ?? ""
    }

    var siwaPrivateKey: String {
        Environment.get("SIWA_PRIVATE_KEY") ?? ""
    }

    func createSIWAPrivateKey() throws -> ApplePrivateKey {
        try ApplePrivateKey(
            kid: JWKIdentifier(string: siwaJWKId),
            privateKey: siwaPrivateKey
        )
    }
}

// MARK: - Edamam

extension Application {

    var edamamAppID: String? {
        Environment.get("EDAMAM_APP_ID")
    }

    var edamamAPIKey: String? {
        Environment.get("EDAMAM_API_KEY")
    }

    var edamamDomain: String {
        "https://api.edamam.com"
    }
}

// MARK: - USDA

extension Application {

    var usdaAPIKey: String? {
        Environment.get("USDA_API_KEY")
    }

    var usdaDomain: String {
        "https://api.nal.usda.gov/fdc"
    }
}

// MARK: - Postgres

extension Application {

    var postgresURL: URL? {
        guard let urlString = Environment.get("DATABASE_URL") else {
            return nil
        }
        return URL(string: urlString)
    }

    var localhostUsername: String? {
        Environment.get("POSTGRES_LOCALHOST_USERNAME")
    }
}
