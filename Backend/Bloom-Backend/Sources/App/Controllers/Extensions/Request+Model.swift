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

  /// Client-driven model selection is disabled for security/cost reasons: an
  /// untrusted client could otherwise force the far more expensive `o3` model
  /// via the `X-Bloom-OpenAI-Model` header. Always returns nil so callers fall
  /// back to the server-chosen default. Re-enable only behind an admin gate.
  var openAIModel: ModelID? {
    nil
  }
}
