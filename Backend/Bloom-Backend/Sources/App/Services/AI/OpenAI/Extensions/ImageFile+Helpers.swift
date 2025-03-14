//
//  ImageFile+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-03-14.
//

import Vapor
import BloomModel
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

extension ImageFile {

  /// Attempts to resize the image data to a new dimension, falling back to the original data if it fails.
  /// - parameter width: The desired width of the image.
  func attemptResizeData(width: CGFloat) -> Data {
    guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
          let originalImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
      return data
    }

    let originalWidth = CGFloat(originalImage.width)
    let originalHeight = CGFloat(originalImage.height)
    let aspectRatio = originalHeight / originalWidth
    let targetHeight = width * aspectRatio

    let options: [CFString: Any] = [
      kCGImageSourceThumbnailMaxPixelSize: max(width, targetHeight),
      kCGImageSourceCreateThumbnailFromImageAlways: true
    ]

    guard let resizedImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
      return data
    }

    let imageType: CFString
    switch fileExtension.lowercased() {
    case "png":
        imageType = UTType.png.identifier as CFString
    case "gif":
        imageType = UTType.gif.identifier as CFString
    case "bmp":
        imageType = UTType.bmp.identifier as CFString
    case "tiff", "tif":
        imageType = UTType.tiff.identifier as CFString
    default:
        imageType = UTType.jpeg.identifier as CFString  // Default to JPEG
    }

    let resizedData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(resizedData, imageType, 1, nil) else {
      return data
    }

    CGImageDestinationAddImage(destination, resizedImage, nil)
    guard CGImageDestinationFinalize(destination) else {
      return data
    }

    return resizedData as Data
  }
}
