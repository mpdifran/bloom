//
//  Codable+Constants.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

// MARK: - JSONEncoder

public extension JSONEncoder {

    static let main: JSONEncoder = {
        let encoder = JSONEncoder()

        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        return encoder
    }()
}

// MARK: - JSONDecoder

public extension JSONDecoder {

    static let main: JSONDecoder = {
        let decoder = JSONDecoder()

        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return decoder
    }()
}
