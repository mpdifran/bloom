//
//  Request+Model.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-06-12.
//

import Vapor
import OpenAIKit
import BloomModel

extension Request {

  var openAIModel: ModelID? {
    guard headers[.Header.openAIModel].first == "o3" else { return nil }

    return ModelID.OSeries.o3
  }
}
