//
//  MockNotificationView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI

struct MockNotificationView: View {
  let title: LocalizedStringKey
  let message: LocalizedStringKey?
  let timestamp: LocalizedStringKey

  var body: some View {
      content
        .glassEffect(.clear, in: .rect(cornerRadius: 20))
  }
}

private extension MockNotificationView {

  var content: some View {
    HStack(alignment: .top) {
      DisplayAppIcon()
        .frame(width: 40)

      VStack(alignment: .leading) {
        HStack {
          Text(title)
            .bold()
          Spacer()
          Text(timestamp)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }

        if let message {
          Text(message)
            .lineLimit(2)
        }
      }
    }
    .font(.footnote)
    .padding(12)
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      MockNotificationView(
        title: "Your Morning Report is Ready",
        message: "Check out how you slept last night.",
        timestamp: "5m ago"
      )
      Spacer()
    }
    .padding()
  }
}
