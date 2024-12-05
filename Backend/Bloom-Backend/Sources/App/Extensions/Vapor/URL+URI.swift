//
//  URL+URI.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-05.
//

import Vapor

extension URL {
  var uri: URI {
    URI(string: absoluteString)
  }
}
