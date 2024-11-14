//
//  Application+TelemetryDeck.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-14.
//

import TelemetryDeck
import Vapor

extension Application {
    var telemetryDeck: TelemetryWrapper {
        TelemetryWrapper(app: self)
    }

    struct TelemetryWrapper {
        private let app: Application

        init(app: Application) {
            self.app = app
        }
    }
}

extension Application.TelemetryWrapper {

    func initialize(appID: String) {
        var config = TelemetryDeck.Config(appID: "F1AC4445-7F73-4026-A19A-FF2250C34853")
        config.testMode = !app.environment.isRelease
        TelemetryDeck.initialize(config: config)
    }

    func signal(
        _ signalName: String,
        parameters: [String: String] = [:],
        floatValue: Double? = nil,
        customUserID: String? = nil
    ) {
        TelemetryDeck.signal(
            signalName,
            parameters: parameters,
            floatValue: floatValue,
            customUserID: customUserID
        )
    }

    func errorOccurred(
        id: String,
        category: ErrorCategory? = nil,
        message: String? = nil,
        parameters: [String: String] = [:],
        floatValue: Double? = nil,
        customUserID: String? = nil
    ) {
        TelemetryDeck.errorOccurred(
            id: id,
            category: category,
            message: message,
            parameters: parameters,
            floatValue: floatValue,
            customUserID: customUserID
        )
    }

    func errorOccurred(
        identifiableError: IdentifiableError,
        category: ErrorCategory = .thrownException,
        message: String? = nil,
        parameters: [String: String] = [:],
        floatValue: Double? = nil,
        customUserID: String? = nil
    ) {
        TelemetryDeck.errorOccurred(
            identifiableError: identifiableError,
            category: category,
            message: message,
            parameters: parameters,
            floatValue: floatValue,
            customUserID: customUserID
        )
    }
}
