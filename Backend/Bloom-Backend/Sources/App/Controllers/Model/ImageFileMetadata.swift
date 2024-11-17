//
//  ImageFileMetadata.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation

struct ImageFileMetadata {
    let filename: String
    let data: Data
}

extension ImageFileMetadata {
  var fileExtension: String? {
    let fileExtension = filename.split(separator: ".").last
    guard let fileExtension else { return nil }
    return String(fileExtension)
  }
}
