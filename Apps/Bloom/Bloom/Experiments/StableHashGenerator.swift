//
//  StableHashGenerator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-11.
//

import Foundation
import CryptoKit

struct StableHashGenerator {
  static func stableHash(experimentId: String, userId: String) -> UInt64 {
    let input = "\(experimentId):\(userId)"
    let inputData = Data(input.utf8)
    let hash = SHA256.hash(data: inputData)

    // Convert first 8 bytes of hash to UInt64
    let hashData = Data(hash)
    let value = UInt64(bigEndian: hashData.prefix(8).withUnsafeBytes { bytes in
      bytes.load(as: UInt64.self)
    })

    return value
  }
}