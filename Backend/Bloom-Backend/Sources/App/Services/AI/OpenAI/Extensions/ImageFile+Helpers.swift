//
//  ImageFile+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-03-14.
//

import Vapor
import BloomModel
import SwiftGD

extension ImageFile {

  var importableFormat: ImportableFormat {
    switch fileExtension.lowercased() {
    case "png":
      return .png
    case "gif":
      return .gif
    case "bmp":
      return .bmp
    case "tiff", "tif":
      return .tiff
    default:
      return .jpg
    }
  }

  /// Attempts to resize the image data to a new dimension, falling back to the original data if it fails.
  /// - parameter width: The desired width of the image.
  func attemptResizeData(width: Int) -> Data {
    do {
      let image = try Image(data: data, as: importableFormat)

      let aspectRatio = Double(image.size.height) / Double(image.size.width)
      let targetHeight = Int(Double(width) * aspectRatio)

      let resizedImage = image.resizedTo(width: width, height: targetHeight)

      if let resizedData = try resizedImage?.export(for: fileExtension) {
        return resizedData
      }
    } catch {
      print(error)
    }
    return data
  }
}

extension Image {

  func export(for fileExtension: String) throws -> Data? {
    switch fileExtension.lowercased() {
    case "png":
      return try export(as: .png)
    case "gif":
      return try export(as: .gif)
    case "bmp":
      return try export(as: .bmp(compression: false))
    case "tiff", "tif":
      return try export(as: .tiff)
    default:
      return try export(as: .jpg(quality: 80))
    }
  }
}
