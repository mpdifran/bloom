//
//  View+RemoveScrollEdgeEffect.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-06.
//

import SwiftUI

extension View {

  @ViewBuilder
  func removeScrollEdgeEffect() -> some View {
    if #available(iOS 26.0, *) {
      scrollEdgeEffectStyle(.none, for: .all)
    } else {
      self
    }
  }
}
