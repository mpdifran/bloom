//
//  ChatBubbleCell.swift
//  AirChat
//
//  Created by Mark DiFranco on 2022-01-23.
//

import SwiftUI

public struct ChatBubbleCell: View {
    let message: String
    let isDirect: Bool
    let isCurrentUser: Bool
    let showTail: Bool

    public init(
        message: String,
        isDirect: Bool,
        isCurrentUser: Bool,
        showTail: Bool
    ) {
        self.message = message
        self.isDirect = isDirect
        self.isCurrentUser = isCurrentUser
        self.showTail = showTail
    }

    public var body: some View {
        ChatBubble(position: isCurrentUser ? .trailing : .leading,
                   showTail: showTail,
                   shouldFill: !isDirect,
                   foregroundColor: foregroundColor,
                   backgroundColor: isCurrentUser ? .accentColor : .chatGrey) {
            Text(message)
        }
    }
}

private extension ChatBubbleCell {

    var foregroundColor: Color {
        switch (isCurrentUser, isDirect) {
        case (true, true):
            return Color(uiColor: .label)
        case (true, false):
            return .white
        case (false, true):
            return Color(uiColor: .label)
        case (false, false):
            return Color(uiColor: .label)
        }
    }
}

struct ChatBubbleCell_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ChatBubbleCell(message: "Hey buddy!", isDirect: false, isCurrentUser: true, showTail: true)
            ChatBubbleCell(message: "Hey, how's it going?", isDirect: false, isCurrentUser: false, showTail: true)
            ChatBubbleCell(message: "It's actually going great!", isDirect: false, isCurrentUser: true, showTail: true)
            ChatBubbleCell(message: "PS It's actually not going great...", isDirect: true, isCurrentUser: true, showTail: true)
            ChatBubbleCell(message: "Oh no what's up?", isDirect: true, isCurrentUser: false, showTail: true)
        }
        .accentColor(.purple)
    }
}
