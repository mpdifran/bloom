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

  /// Attempts to resize the image data to a new dimension, falling back to the original data if it fails.
  /// - parameter width: The desired width of the image.
  func attemptResizeData(width: Int) -> Data {
    do {
      let image = try Image(data: data)

      let aspectRatio = Double(image.size.height) / Double(image.size.width)
      let targetHeight = Int(Double(width) * aspectRatio)

      let resizedImage = image.resizedTo(width: width, height: targetHeight)

      switch fileExtension.lowercased() {
      case "png":
        return try resizedImage?.export(as: .png) ?? data
      case "gif":
        return try resizedImage?.export(as: .gif) ?? data
      case "bmp":
        return try resizedImage?.export(as: .bmp(compression: false)) ?? data
      case "tiff", "tif":
        return try resizedImage?.export(as: .tiff) ?? data
      default:
        return try resizedImage?.export(as: .jpg(quality: 80)) ?? data
      }
    } catch {
      print(error)
    }
    return data
  }
}
