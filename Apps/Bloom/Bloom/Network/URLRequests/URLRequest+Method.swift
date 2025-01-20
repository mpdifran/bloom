//
//  URLRequest+Method.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-02.
//

import Foundation

extension URLRequest {
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }

    var method: Method? {
        get { return Method(rawValue: httpMethod ?? "") }
        set { httpMethod = newValue?.rawValue }
    }
}
