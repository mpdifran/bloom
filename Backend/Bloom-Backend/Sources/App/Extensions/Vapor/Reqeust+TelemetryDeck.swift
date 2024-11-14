//
//  Reqeust+TelemetryDeck.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-14.
//

import TelemetryDeck
import Vapor

extension Request {
    var telemetryDeck: TelemetryWrapper {
        TelemetryWrapper(app: application, request: self)
    }

    struct TelemetryWrapper {
        private let app: Application
        private let request: Request

        init(app: Application, request: Request) {
            self.app = app
            self.request = request
        }
    }
}

extension Request.TelemetryWrapper {

    func signal(
        _ signalName: String,
        parameters: [String: String] = [:],
        floatValue: Double? = nil
    ) {
        TelemetryDeck.signal(
            signalName,
            parameters: parameters,
            floatValue: floatValue,
            customUserID: userIdentifier
        )
    }

    func errorOccurred(
        id: String,
        category: ErrorCategory? = nil,
        message: String? = nil,
        parameters: [String: String] = [:],
        floatValue: Double? = nil
    ) {
        TelemetryDeck.errorOccurred(
            id: id,
            category: category,
            message: message,
            parameters: parameters,
            floatValue: floatValue,
            customUserID: userIdentifier
        )
    }

    func errorOccurred(
        identifiableError: IdentifiableError,
        category: ErrorCategory = .thrownException,
        message: String? = nil,
        parameters: [String: String] = [:],
        floatValue: Double? = nil
    ) {
        TelemetryDeck.errorOccurred(
            identifiableError: identifiableError,
            category: category,
            message: message,
            parameters: parameters,
            floatValue: floatValue,
            customUserID: userIdentifier
        )
    }
}

private extension Request.TelemetryWrapper {

    var userIdentifier: String? {
        // The XFF header may sometimes be comma-separated (this has been proven to be true on Google Cloud services).
        //
        // The header will include the client IP address first, followed by a number of proxy services such as load
        // balancers. These can change often and thus lead to the identifier changing for the same 'user' reporting
        // them multiple times.
        //
        // Source: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For
        //
        // To avoid this problem, we fetch only the first IP address within the header.
        let userIdentifier = request.headers.first(name: .xForwardedFor)?.components(separatedBy: ",").first ?? request.remoteAddress?.description

        return userIdentifier
    }
}
