//
//  ConversationRelativeTimeLabel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-08.
//

import SwiftUI

struct ConversationRelativeTimeLabel: View {
  let date: Date

  var body: some View {
    Text(DateFormatter.conversationRelativeDateOrTime(date: date))
      .font(.caption)
      .fontDesign(.rounded)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: true, vertical: true)
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      Spacer()
      ConversationRelativeTimeLabel(date: .now)
      ConversationRelativeTimeLabel(date: .now.addingTimeInterval(-86_400))
      ConversationRelativeTimeLabel(date: .now.addingTimeInterval(-259_200))
      ConversationRelativeTimeLabel(date: .now.addingTimeInterval(-691_200))
      Spacer()
    }
    .horizontallyCentered()
  }
}
