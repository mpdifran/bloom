//
//  View+RemoveScrollEdgeEffect.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-06.
//

import SwiftUI

extension View {

  @ViewBuilder
  func removeScrollEdgeEffect(shouldHide: Bool) -> some View {
      scrollEdgeEffectHidden(shouldHide, for: .top)
  }
}
