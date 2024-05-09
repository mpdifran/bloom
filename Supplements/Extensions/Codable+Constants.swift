//
//  Codable+Constants.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

// MARK: - JSONEncoder

extension JSONEncoder {

    static let main: JSONEncoder = {
        let encoder = JSONEncoder()

        return encoder
    }()
}

// MARK: - JSONDecoder

extension JSONDecoder {

    static let main: JSONDecoder = {
        let decoder = JSONDecoder()

        return decoder
    }()
}
