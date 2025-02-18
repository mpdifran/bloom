//
//  View+SafeAreaBlur.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-17.
//

import SwiftUI

extension View {

  func topSafeAreaBlur(fill: Material = .thick) -> some View {
    safeAreaInset(edge: .top) {
      Rectangle()
        .fill(fill)
        .ignoresSafeArea()
        .frame(height: 0)
    }
  }

  func topSafeAreaFill(_ fill: some ShapeStyle = AnyShapeStyle(.background.secondary)) -> some View {
    safeAreaInset(edge: .top) {
      Rectangle()
        .fill(fill)
        .ignoresSafeArea()
        .frame(height: 0)
    }
  }
}
