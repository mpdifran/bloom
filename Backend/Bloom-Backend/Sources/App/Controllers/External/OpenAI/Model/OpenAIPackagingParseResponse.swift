//
//  OpenAIPackagingParseResponse.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-12.
//

import Foundation

struct OpenAIPackagingParseResponse: Codable {
    let brandName: String
    let productName: String
    let flavour: String?
}
