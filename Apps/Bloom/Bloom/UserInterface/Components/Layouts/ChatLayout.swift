//
//  ChatLayout.swift
//  Bloom
//
//  Created by Zach Radford on 2025-05-07.
//

import SwiftUI

private struct ChatVariadicView: _VariadicView_MultiViewRoot {
  /// The chat view uses a double-flip technique to achieve correct scrolling behaviour:
  /// 1. The content inside the ScrollView is flipped upside down so new messages appear at the bottom.
  /// 2. The entire ScrollView is then flipped upside down to correct the orientation.
  /// This creates the illusion of messages scrolling up from the bottom while maintaining proper layout.
  func body(children: _VariadicView.Children) -> some View {
    List {
      ForEach(children.reversed()) { child in
        child
          .flippedVertically()
          .listRowBackground(Color.clear)
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
      }
    }
    .listStyle(.plain)
    .environment(\.defaultMinListRowHeight, 0)
    .listRowSpacing(4)
    .flippedVertically()
    .padding(.top, -8) // since we don't have access to the tableView contentInset, cut into the top by the scroll content offset magic number.
  }
}

struct ChatLayout<Content: View>: View {

  var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    _VariadicView.Tree(ChatVariadicView()) {
      content
    }
  }
}
