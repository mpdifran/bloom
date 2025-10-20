//
//  View+HorizontalAlignment.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-24.
//

import SwiftUI

public extension View {

  func horizontalAlignment(_ alignment: HorizontalAlignment) -> some View {
    HStack {
      if alignment != .leading {
        Spacer(minLength: 0)
      }

      self

      if alignment != .trailing {
        Spacer(minLength: 0)
      }
    }
  }
}
