//
//  ChatEmojiCell.swift
//  AirChat
//
//  Created by Mark DiFranco on 2022-02-01.
//

import SwiftUI

public struct ChatEmojiCell: View {
    let emojiMessage: String
    let isCurrentUser: Bool

    public init(emojiMessage: String, isCurrentUser: Bool) {
        self.emojiMessage = emojiMessage
        self.isCurrentUser = isCurrentUser
    }

    public var body: some View {
        HStack {
            if isCurrentUser {
                Spacer(minLength: 60)
            }

            Text(emojiMessage)
                .font(.system(size: 50))

            if !isCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .padding(isCurrentUser ? .trailing : .leading)
    }
}

struct ChatEmojiCell_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 4) {
                ChatBubble(position: .trailing, showTail: false, shouldFill: true, backgroundColor: .accentColor) {
                    Text("Hey")
                        .foregroundColor(.white)
                }
                ChatEmojiCell(emojiMessage: "🥳🤟🏻", isCurrentUser: true)

                ChatBubble(position: .leading, showTail: false, shouldFill: true, backgroundColor: .chatGrey) {
                    Text("What's up?")
                }
                ChatEmojiCell(emojiMessage: "🥳🤟🏻", isCurrentUser: false)
            }
        }
    }
}
