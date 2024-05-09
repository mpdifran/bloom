//
//  ChatBubble.swift
//  AirChat
//
//  Created by Mark DiFranco on 2022-01-23.
//

import SwiftUI

public struct ChatBubble<Content>: View where Content: View {
    public enum Position {
        case leading, trailing
    }

    let position: Position
    let showTail: Bool
    let shouldFill: Bool
    let foregroundColor: Color
    let backgroundColor : Color
    let content: () -> Content

    public init(
        position: Position,
        showTail: Bool = false,
        shouldFill: Bool = true,
        foregroundColor: Color = Color(uiColor: .label),
        backgroundColor: Color,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.position = position
        self.showTail = showTail
        self.shouldFill = shouldFill
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.content = content
    }

    public var body: some View {
        HStack {
            if position == .trailing {
                Spacer(minLength: 60)
            }

            HStack(spacing: 0) {
                content()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .frame(minWidth: 40)
                    .foregroundColor(foregroundColor)
                    .background(backgroundView)
            }
            .padding(position == .leading ? .leading : .trailing)

            if position == .leading {
                Spacer(minLength: 60)
            }
        }
    }
}

extension ChatBubble {

    var tailPosition: ChatBubbleShape.TailPosition {
        guard showTail else { return .none }

        switch position {
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }

    var backgroundView: some View {
        if shouldFill {
            return ChatBubbleShape(tailPosition: tailPosition)
                .fill(backgroundColor)
                .asAny
        } else {
            return ChatBubbleShape(tailPosition: tailPosition)
                .stroke(style: StrokeStyle(lineWidth: 3, dash: [4]))
                .fill(backgroundColor)
                .background(
                    ChatBubbleShape(tailPosition: tailPosition)
                        .fill(backgroundColor.opacity(0.3))
                )
                .asAny
        }
    }
}

struct ChatBubble_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 8) {
                ChatBubble(position: .leading, showTail: true, backgroundColor: .chatGrey) {
                    Text("Hello World")
                }
                ChatBubble(position: .trailing, foregroundColor: .white, backgroundColor: .blue) {
                    Text("Why hello")
                }
                ChatBubble(position: .trailing, showTail: true, foregroundColor: .white, backgroundColor: .blue) {
                    Text("How are you doing?")
                }
                ChatBubble(position: .leading, showTail: true, backgroundColor: .chatGrey) {
                    Text("I'm doing great, this is a really great chat app don't you say?")
                }
                ChatBubble(position: .trailing, showTail: true, foregroundColor: .white, backgroundColor: .blue) {
                    Text("Yes, it is certainly splendid. And it's built with no server!")
                }
                ChatBubble(position: .trailing, showTail: true, foregroundColor: .white, backgroundColor: .blue) {
                    Text("I")
                }
                ChatBubble(position: .trailing, showTail: true, foregroundColor: .white, backgroundColor: .blue) {
                    Text("🥳")
                }
                ChatBubble(position: .leading, showTail: true, shouldFill: false, backgroundColor: .chatGrey) {
                    Text("This is a secret direct message, don't tell anyone!")
                }
                ChatBubble(position: .trailing, showTail: true, shouldFill: false, backgroundColor: .blue) {
                    Text("OK I won't!")
                }
            }
        }
        .background(Color(uiColor: .systemBackground))
//        .environment(\.colorScheme, .dark)
    }
}
