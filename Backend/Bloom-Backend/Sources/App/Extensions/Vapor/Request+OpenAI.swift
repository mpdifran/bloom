//
//  Request+OpenAI.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Vapor
@preconcurrency import OpenAIKit

extension Request {

    private struct OpenAIKey: StorageKey {
        typealias Value = OpenAIKit.Client
    }

    public var openAI: OpenAIKit.Client {
        if let client = application.storage[OpenAIKey.self] {
            return client
        } else {
            let client = application.openAI
            application.storage[OpenAIKey.self] = client
            return client
        }
    }
}
