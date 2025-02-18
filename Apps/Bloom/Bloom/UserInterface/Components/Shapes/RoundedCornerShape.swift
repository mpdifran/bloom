//
//  RoundedCornerShape.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-18.
//

import SwiftUI

struct RoundedCornerShape: Shape {
  var radius: CGFloat
  var corners: UIRectCorner

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}
