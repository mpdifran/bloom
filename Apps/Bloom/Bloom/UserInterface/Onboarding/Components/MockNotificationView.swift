//
//  MockNotificationView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI

struct MockNotificationView: View {
    let title: String
    let message: String
    let timestamp: String

    var body: some View {
        HStack(alignment: .top) {
            Image(.bloomAppIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
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

                if message.isNotEmpty {
                    Text(message)
                        .lineLimit(2)
                }
            }
        }
        .font(.footnote)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        }
    }
}

#Preview {
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
