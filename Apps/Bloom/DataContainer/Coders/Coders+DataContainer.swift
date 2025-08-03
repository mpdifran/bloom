//
//  Coders+DataContainer.swift
//  DataContainer
//
//  Created by Assistant on 2025-08-02.
//

import Foundation

// MARK: - JSONEncoder

public extension JSONEncoder {
    
    static let dataContainer: JSONEncoder = {
        let encoder = JSONEncoder()
        
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.dateEncodingStrategy = .iso8601
        
        return encoder
    }()
}

// MARK: - JSONDecoder

public extension JSONDecoder {
    
    static let dataContainer: JSONDecoder = {
        let decoder = JSONDecoder()
        
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601
        
        return decoder
    }()
}