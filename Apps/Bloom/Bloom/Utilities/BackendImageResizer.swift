//
//  BackendImageResizer.swift
//  Bloom
//
//  Created by Assistant on 2025-10-17.
//

import UIKit

enum BackendImageResizer {
  /// Resizes an image to 300pt width and converts to JPEG data for backend storage
  static func resize(_ image: UIImage?) -> Data? {
    image?.resized(toWidth: 300)?.jpegData(compressionQuality: 0.75)
  }
}
