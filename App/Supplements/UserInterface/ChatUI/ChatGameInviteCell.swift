//
//  ChatGameInviteCell.swift
//  AirChatUI
//
//  Created by Mark DiFranco on 2023-06-25.
//

import SwiftUI

public struct ChatGameInviteCell<Content: View>: View {
    let gameName: String
    let inviteMessage: String
    let isDirect: Bool
    let isCurrentUser: Bool
    let isIncompatible: Bool
    let showTail: Bool
    let contentBuilder: () -> Content

    public init(
        gameName: String,
        inviteMessage: String,
        isDirect: Bool,
        isCurrentUser: Bool,
        isIncompatible: Bool,
        showTail: Bool,
        @ViewBuilder contentBuilder: @escaping () -> Content
    ) {
        self.gameName = gameName
        self.inviteMessage = inviteMessage
        self.isDirect = isDirect
        self.isCurrentUser = isCurrentUser
        self.isIncompatible = isIncompatible
        self.showTail = showTail
        self.contentBuilder = contentBuilder
    }

    public var body: some View {
        ChatBubble(
            position: isCurrentUser ? .trailing : .leading,
            showTail: showTail,
            shouldFill: !isDirect,
            foregroundStyle: foregroundColor,
            backgroundStyle: backgroundColor
        ) {
            VStack(alignment: .leading) {
                contentBuilder()
                    .roundedBorder(10, color: Color(uiColor: .systemFill))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(uiColor: .systemFill))
                    )
                    .aspectRatio(1, contentMode: .fit)

                HStack(alignment: .top) {
                    Image(systemName: isIncompatible ? "exclamationmark.triangle.fill" : "gamecontroller")

                    VStack(alignment: .leading) {
                        Text(gameName)
                            .font(.caption)
                        Text(inviteMessage)
                            .font(.caption2)
                            .foregroundColor(inviteMessageColor)
                    }
                }
            }
            .frame(maxWidth: 200)
            .padding(.top, 5)
        }
    }
}

private extension ChatGameInviteCell {

    var foregroundColor: Color {
        switch (isCurrentUser, isDirect, isIncompatible) {
        case (_, _, true):
            return .black
        case (true, false, _):
            return .white
        default:
            return Color(uiColor: .label)
        }
    }

    var inviteMessageColor: Color {
        if isIncompatible {
            return Color(uiColor: .init(white: 0.3, alpha: 1))
        }
        if isCurrentUser && !isDirect {
            return .white
        }
        return .secondary
    }

    var backgroundColor: Color {
        if isIncompatible {
            return .yellow
        }
        return isCurrentUser ? .accentColor : .chatGrey
    }
}

struct ChatGameInviteCell_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ChatGameInviteCell(
                gameName: "Tic-Tac-Toe",
                inviteMessage: "Mark has invited you to play Tic-Tac-Toe",
                isDirect: false,
                isCurrentUser: false,
                isIncompatible: false,
                showTail: true
            ) {
                Image(systemName: "gamecontroller")
                    .resizable()
            }

            ChatGameInviteCell(
                gameName: "Hangman",
                inviteMessage: "Invite Sent",
                isDirect: false,
                isCurrentUser: true,
                isIncompatible: false,
                showTail: true
            ) {
                Image(systemName: "gamecontroller")
                    .resizable()
            }

            ChatGameInviteCell(
                gameName: "Tic-Tac-Toe",
                inviteMessage: "Mark has invited you to play Tic-Tac-Toe",
                isDirect: true,
                isCurrentUser: false,
                isIncompatible: false,
                showTail: true
            ) {
                Image(systemName: "gamecontroller")
                    .resizable()
            }

            ChatGameInviteCell(
                gameName: "Hangman",
                inviteMessage: "Invite Sent",
                isDirect: true,
                isCurrentUser: true,
                isIncompatible: false,
                showTail: true
            ) {
                Image(systemName: "gamecontroller")
                    .resizable()
            }

            ChatGameInviteCell(
                gameName: "Tic-Tac-Toe",
                inviteMessage: "Your version is too old. Tap to update AirChat.",
                isDirect: false,
                isCurrentUser: false,
                isIncompatible: true,
                showTail: true
            ) {
                Image(systemName: "gamecontroller")
                    .resizable()
            }

            ChatGameInviteCell(
                gameName: "Hangman",
                inviteMessage: "Invite Sent",
                isDirect: false,
                isCurrentUser: true,
                isIncompatible: true,
                showTail: true
            ) {
                Image(systemName: "gamecontroller")
                    .resizable()
            }
        }
    }
}
