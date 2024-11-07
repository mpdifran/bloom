//
//  URL+QueryItems.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-07.
//

import Foundation

extension URL {

    func setting(queryItems: [URLQueryItem]) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }

        components.queryItems = queryItems

        return components.url
    }

    func adding(queryItems: [URLQueryItem]) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }

        let existingItems = components.queryItems ?? []
        components.queryItems = existingItems + queryItems

        return components.url
    }
}
