//
//  Collection+SafeSubscript.swift
//  BloomFoundation
//
//  Created by Claude on 2025-06-04.
//

import Foundation

public extension Collection {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}