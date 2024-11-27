//
//  ImageProcessing.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-26.
//

import Foundation
import NIO
import NIOExtras
import Vapor

enum ImageType: String {
    case bmp
    case jpeg
    case png
    case webp
}

protocol ImageProcessing {
    /// Determines an image type from the data representation of the image.
    func determineImageType(_ imageData: Data) -> ImageType?
}

public struct ImageProcessor: ImageProcessing {

  func determineImageType(_ imageData: Data) -> ImageType? {
      if imageData.starts(with: [0x89, 0x50, 0x4E, 0x47]) { // PNG
          return .png
      } else if imageData.starts(with: [0xFF, 0xD8, 0xFF]) { // JPEG
          return .jpeg
      } else if imageData.starts(with: [0x42, 0x4D]) { // BMP
          return .bmp
      } else if imageData.starts(with: [0x52, 0x49, 0x46, 0x46]) &&
                  imageData.dropFirst(8).starts(with: [0x57, 0x45, 0x42, 0x50]) { // WebP
          return .webp
      }
      return nil
  }
}
