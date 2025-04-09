//
//  ChatUploadFileResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-09.
//

import Foundation

public struct ChatUploadFileResponse: Codable, Equatable, Sendable {
  public let fileIDs: [String]

  public init(fileIDs: [String]) {
    self.fileIDs = fileIDs
  }
}
