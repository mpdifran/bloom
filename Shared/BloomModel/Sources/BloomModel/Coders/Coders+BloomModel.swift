//
//  JSONEncoder+BloomModel.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-20.
//

import Foundation

// MARK: - JSONEncoder

public extension JSONEncoder {

    static let bloomModel: JSONEncoder = {
        let encoder = JSONEncoder()

        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.dateEncodingStrategy = .iso8601

        return encoder
    }()
}

// MARK: - JSONDecoder

public extension JSONDecoder {

    static let bloomModel: JSONDecoder = {
        let decoder = JSONDecoder()

        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601

        return decoder
    }()
}
