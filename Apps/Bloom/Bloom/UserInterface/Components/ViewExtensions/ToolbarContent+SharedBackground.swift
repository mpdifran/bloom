//
//  ToolbarContent+SharedBackground.swift
//  Bloom
//

import SwiftUI

extension ToolbarContent {

  @ToolbarContentBuilder
  func hiddenSharedBackground() -> some ToolbarContent {
    if #available(iOS 26.0, *) {
      self.sharedBackgroundVisibility(.hidden)
    } else {
      self
    }
  }
}
