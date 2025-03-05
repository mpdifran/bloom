//
//  SuggestedReminder.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-03-05.
//

import Foundation

public struct SuggestedReminder: Codable, Equatable, Sendable {
  public let title: String

  public init(title: String) {
    self.title = title
  }
}
