//
//  NSImage+PNG.swift
//  Gardener
//
//  Created by Zach Radford on 2025-01-03.
//

import AppKit

extension NSImage {
  func pngData() -> Data? {
    // Get the TIFF representation of the NSImage
    guard let tiffData = self.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData) else {
      return nil
    }

    // Convert the bitmap representation to PNG data
    return bitmapRep.representation(using: .png, properties: [:])
  }
}
