//
//  CameraReticuleShapeView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-07.
//

import SwiftUI

private extension CGFloat {
  static let gapSize: CGFloat = 0.04
}

struct CameraReticuleShapeView: View {
  let lineWidth: CGFloat
  let cornerRadius: CGFloat

  init(
    lineWidth: CGFloat = 4,
    cornerRadius: CGFloat = 30
  ) {
    self.lineWidth = lineWidth
    self.cornerRadius = cornerRadius
  }

  var body: some View {
    ZStack {
      // Top & Bottom Strokes
      RoundedRectangle(cornerRadius: cornerRadius)
        .trim(from: .gapSize, to: 0.25 - .gapSize)
        .stroke(.tint, lineWidth: lineWidth)

      RoundedRectangle(cornerRadius: cornerRadius)
        .trim(from: 0.25 + .gapSize, to: 0.5 - .gapSize)
        .stroke(.tint, lineWidth: lineWidth)

      // Left & Right Strokes
      RoundedRectangle(cornerRadius: cornerRadius)
        .trim(from: 0.5 + .gapSize, to: 0.75 - .gapSize)
        .stroke(.tint, lineWidth: lineWidth)

      RoundedRectangle(cornerRadius: cornerRadius)
        .trim(from: 0.75 + .gapSize, to: 1 - .gapSize)
        .stroke(.tint, lineWidth: lineWidth)
    }
  }
}

#Preview {
  CameraReticuleShapeView()
    .aspectRatio(1, contentMode: .fit)
    .padding()
}
