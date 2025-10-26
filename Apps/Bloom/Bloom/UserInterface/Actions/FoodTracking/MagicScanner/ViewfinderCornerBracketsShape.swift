//
//  ViewfinderCornerBracketsShape.swift
//  Bloom
//
//  Created by Claude on 2025-10-25.
//

import SwiftUI

/// A shape that draws corner brackets resembling a camera viewfinder.
/// Only the corners are drawn, with gaps in the middle of each side.
struct ViewfinderCornerBracketsShape: Shape {
  /// The length of each bracket arm as a percentage of the side (0.0 to 0.5)
  var bracketLengthRatio: CGFloat = 0.3

  /// The corner radius for the rounded corners
  var cornerRadius: CGFloat = 20

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let bracketLength = min(rect.width, rect.height) * bracketLengthRatio

    // Top-left corner
    drawTopLeftCorner(in: rect, path: &path, bracketLength: bracketLength)

    // Top-right corner
    drawTopRightCorner(in: rect, path: &path, bracketLength: bracketLength)

    // Bottom-right corner
    drawBottomRightCorner(in: rect, path: &path, bracketLength: bracketLength)

    // Bottom-left corner
    drawBottomLeftCorner(in: rect, path: &path, bracketLength: bracketLength)

    return path
  }

  private func drawTopLeftCorner(in rect: CGRect, path: inout Path, bracketLength: CGFloat) {
    // Start from vertical arm, draw continuous L-shape
    path.move(to: CGPoint(x: rect.minX, y: rect.minY + bracketLength))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
    path.addArc(
      center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
      radius: cornerRadius,
      startAngle: .degrees(180),
      endAngle: .degrees(270),
      clockwise: false
    )
    path.addLine(to: CGPoint(x: rect.minX + bracketLength, y: rect.minY))
  }

  private func drawTopRightCorner(in rect: CGRect, path: inout Path, bracketLength: CGFloat) {
    // Start from horizontal arm, draw continuous L-shape
    path.move(to: CGPoint(x: rect.maxX - bracketLength, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
    path.addArc(
      center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
      radius: cornerRadius,
      startAngle: .degrees(270),
      endAngle: .degrees(0),
      clockwise: false
    )
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + bracketLength))
  }

  private func drawBottomRightCorner(in rect: CGRect, path: inout Path, bracketLength: CGFloat) {
    // Start from vertical arm, draw continuous L-shape
    path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - bracketLength))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
    path.addArc(
      center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
      radius: cornerRadius,
      startAngle: .degrees(0),
      endAngle: .degrees(90),
      clockwise: false
    )
    path.addLine(to: CGPoint(x: rect.maxX - bracketLength, y: rect.maxY))
  }

  private func drawBottomLeftCorner(in rect: CGRect, path: inout Path, bracketLength: CGFloat) {
    // Start from horizontal arm, draw continuous L-shape
    path.move(to: CGPoint(x: rect.minX + bracketLength, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
    path.addArc(
      center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
      radius: cornerRadius,
      startAngle: .degrees(90),
      endAngle: .degrees(180),
      clockwise: false
    )
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - bracketLength))
  }
}

#Preview("Viewfinder Brackets") {
  ZStack {
    Color.black
      .ignoresSafeArea()

    ViewfinderCornerBracketsShape(
      bracketLengthRatio: 0.25,
      cornerRadius: 20
    )
    .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
    .aspectRatio(1, contentMode: .fit)
    .padding(40)
  }
}
