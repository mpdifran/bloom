//
//  WatchBiologicalSexData.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-02-06.
//

import Foundation

/// Data synced from iOS to watch containing biological sex.
public struct WatchBiologicalSexData: Codable, Sendable {
  public let isFemale: Bool

  public init(isFemale: Bool) {
    self.isFemale = isFemale
  }
}
