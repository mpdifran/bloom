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
