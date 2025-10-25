//
//  UIImage+Crop.swift
//  Bloom
//
//  Created by Claude on 2025-10-25.
//

import UIKit

extension UIImage {
  /// Crops the image to a square (1:1 aspect ratio) by taking the center portion.
  /// - Returns: A new square image, or nil if cropping fails.
  func croppedToSquare() -> UIImage? {
    let originalSize = size
    let sideLength = min(originalSize.width, originalSize.height)

    // Calculate the origin point to center the crop
    let x = (originalSize.width - sideLength) / 2
    let y = (originalSize.height - sideLength) / 2

    let cropRect = CGRect(x: x, y: y, width: sideLength, height: sideLength)

    guard let cgImage = cgImage?.cropping(to: cropRect) else {
      return nil
    }

    return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
  }
}
