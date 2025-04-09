//
//  ChatUploadFileRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-09.
//

import Foundation

public struct ChatUploadFileRequest: Codable, Equatable, Sendable {
  public let images: [Data]

  public init(images: [Data]) {
    self.images = images
  }
}
