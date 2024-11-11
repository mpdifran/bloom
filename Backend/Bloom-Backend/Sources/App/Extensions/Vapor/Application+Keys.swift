//
//  Application+Keys.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Vapor

extension Application {

    func printEnvironmentInfo() {
        logger.info("Environment: \(environment.name)")

        if let _ = postgresURL {
            logger.info("Postgres URL set")
        } else {
            logger.info("Using local Postgres")
        }
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
}
