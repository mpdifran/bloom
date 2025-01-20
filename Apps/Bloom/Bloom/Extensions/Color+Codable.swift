//
//  Color+Codable.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-07.
//

import SwiftUI

// https://nilcoalescing.com/blog/EncodeAndDecodeSwiftUIColor/

extension Color: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder
            .container(keyedBy: CodingKeys.self)
        let colorSpace = try container
            .decode(String.self, forKey: .colorSpace)
        let components = try container
            .decode([CGFloat].self, forKey: .components)

        guard
            let cgColorSpace = CGColorSpace(name: colorSpace as CFString),
            let cgColor = CGColor(
                colorSpace: cgColorSpace, components: components
            )
        else {
            throw CodingError.wrongData
        }

        self = Color(cgColor: cgColor)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let colorSpace = cgColor?.colorSpace?.name

        guard
            let components = cgColor?.components
        else {
            throw CodingError.wrongData
        }

        // Some color pickers don't have a color space name, so default to this one.
        try container.encode(colorSpace as? String ?? "kCGColorSpaceExtendedSRGB", forKey: .colorSpace)
        try container.encode(components, forKey: .components)
    }
}

extension Color {
    enum CodingKeys: String, CodingKey {
        case colorSpace
        case components
    }

    enum CodingError: Error {
        case wrongColor
        case wrongData
    }
}
