//
//  Schema.Object+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-21.
//

import Foundation
import OpenAIKit

extension Schema.Object {

  func asString() -> String {
    let data = try! JSONEncoder.bloomModel.encode(self)
    return String(data: data, encoding: .utf8)!
  }
}
