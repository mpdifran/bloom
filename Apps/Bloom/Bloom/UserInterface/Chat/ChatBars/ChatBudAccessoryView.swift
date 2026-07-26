//
//  ChatBudAccessoryView.swift
//  Bloom
//
//  Created by Claude on 2026-07-25.
//

import SwiftUI
import AppUI

/// Compact "Chat with Bud" launcher shown in the tab bar bottom accessory (all tabs).
/// Chat-only — logging actions live in the Actions tab. The tap handler is attached by the host.
struct ChatBudAccessoryView: View {
  var body: some View {
    HStack {
      Image(.budPeek)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(square: 34)
        .foregroundStyle(.secondary)

      Text("Chat with Bud")
        .foregroundStyle(.secondary)

      Spacer(minLength: 0)
    }
    .selectable()
    .padding(.horizontal, 8)
  }
}
