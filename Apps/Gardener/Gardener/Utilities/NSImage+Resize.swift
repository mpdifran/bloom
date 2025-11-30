//
//  NSImage+Resize.swift
//  Gardener
//
//  Created by Claude Code on 2025-11-30.
//

import AppKit
import Foundation

extension NSImage {

  /// Resize the image to a maximum width while maintaining aspect ratio
  /// - Parameter maxWidth: The maximum width in pixels
  /// - Returns: The resized image
  func resized(toMaxWidth maxWidth: CGFloat) -> NSImage? {
    let aspectRatio = size.height / size.width

    // Only resize if the image is larger than maxWidth
    guard size.width > maxWidth else {
      return self
    }

    let newWidth = maxWidth
    let newHeight = newWidth * aspectRatio
    let newSize = NSSize(width: newWidth, height: newHeight)

    let newImage = NSImage(size: newSize)
    newImage.lockFocus()
    defer { newImage.unlockFocus() }

    let context = NSGraphicsContext.current
    context?.imageInterpolation = .high

    draw(
      in: NSRect(origin: .zero, size: newSize),
      from: NSRect(origin: .zero, size: size),
      operation: .copy,
      fraction: 1.0
    )

    return newImage
  }

  /// Convert the image to JPEG data with specified quality
  /// - Parameter quality: The quality factor (0.0 to 1.0)
  /// - Returns: JPEG data or nil if conversion fails
  func jpegData(compressionQuality quality: Double) -> Data? {
    guard let tiffData = tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData) else {
      return nil
    }

    return bitmapImage.representation(
      using: .jpeg,
      properties: [.compressionFactor: quality]
    )
  }
}
