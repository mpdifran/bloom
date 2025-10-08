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
    TimelineView(.everyMinute) { _ in 
      Text(DateFormatter.conversationRelativeDateOrTime(date: date))
        .font(.caption)
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)
    }
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
