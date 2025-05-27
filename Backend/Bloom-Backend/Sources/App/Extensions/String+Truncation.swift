//
//  String+Truncation.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-05-27.
//

import Foundation

extension String {
  func truncated(to length: Int) -> String {
    if count <= length {
      return self
    }
    let endIndex = index(startIndex, offsetBy: length - 3)
    return String(self[..<endIndex]) + "..."
  }
}