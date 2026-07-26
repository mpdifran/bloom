//
//  ToolbarContent+SharedBackground.swift
//  Bloom
//

import SwiftUI

extension ToolbarContent {

  @ToolbarContentBuilder
  func hiddenSharedBackground() -> some ToolbarContent {
      self.sharedBackgroundVisibility(.hidden)
  }
}
