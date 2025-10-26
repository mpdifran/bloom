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
    // Normalize orientation first to ensure consistent coordinate space
    let normalizedImage = fixedOrientation()

    let originalSize = normalizedImage.size
    let sideLength = min(originalSize.width, originalSize.height)

    // Calculate the origin point to center the crop
    let x = (originalSize.width - sideLength) / 2
    let y = (originalSize.height - sideLength) / 2

    let cropRect = CGRect(x: x, y: y, width: sideLength, height: sideLength)

    guard let cgImage = normalizedImage.cgImage?.cropping(to: cropRect) else {
      return nil
    }

    // Return with .up orientation since the image is now normalized
    return UIImage(cgImage: cgImage, scale: normalizedImage.scale, orientation: .up)
  }

  /// Normalizes the image orientation by redrawing if needed.
  /// - Returns: A new image with .up orientation and correctly oriented pixel data.
  private func fixedOrientation() -> UIImage {
    // If already up orientation, return as-is
    guard imageOrientation != .up else {
      return self
    }

    // Redraw the image to normalize orientation
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false

    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { _ in
      draw(in: CGRect(origin: .zero, size: size))
    }
  }
}
