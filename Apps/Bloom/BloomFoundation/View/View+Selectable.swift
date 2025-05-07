//
//  View+Selectable.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-13.
//

import SwiftUI

public extension View {

  func selectable() -> some View {
    contentShape(Rectangle())
  }
}
