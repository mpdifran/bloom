//
//  ChatLayout.swift
//  Bloom
//
//  Created by Zach Radford on 2025-05-07.
//

import SwiftUI

struct ChatLayout: _VariadicView_MultiViewRoot {

  func body(children: _VariadicView.Children) -> some View {
    List {
      ForEach(children.reversed()) { child in
        child
          .flippedVertically()
          .listRowBackground(Color.clear)
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .padding(.vertical, 4)
      }
    }
    .listStyle(.plain)
    .flippedVertically()
  }
}

struct ChatList<Content: View>: View {

  var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    _VariadicView.Tree(ChatLayout()) {
      content
    }
  }
}
