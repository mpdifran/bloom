//
//  ChatBubble.swift
//  AirChat
//
//  Created by Mark DiFranco on 2022-01-23.
//

import SwiftUI
import BloomUI

public enum ChatBubblePosition {
  case leading, trailing
}

public struct ChatBubble<Content, ForegroundStyle, BackgroundStyle>: View where Content: View, ForegroundStyle: ShapeStyle, BackgroundStyle: ShapeStyle {
  let position: ChatBubblePosition
  let showTail: Bool
  let shouldFill: Bool
  let includePadding: Bool
  let foregroundStyle: ForegroundStyle
  let backgroundStyle: BackgroundStyle
  let onCopy: (() -> Void)?
  let content: () -> Content

  public init(
    position: ChatBubblePosition,
    showTail: Bool = false,
    shouldFill: Bool = true,
    includePadding: Bool = true,
    foregroundStyle: ForegroundStyle = Color(uiColor: .label),
    backgroundStyle: BackgroundStyle,
    onCopy: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.position = position
    self.showTail = showTail
    self.shouldFill = shouldFill
    self.includePadding = includePadding
    self.foregroundStyle = foregroundStyle
    self.backgroundStyle = backgroundStyle
    self.onCopy = onCopy
    self.content = content
  }

  public var body: some View {
    if includePadding {
      HStack {
        if position == .trailing {
          Spacer(minLength: 60)
        }

        HStack(spacing: 0) {
          content()
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .frame(minWidth: 40)
            .foregroundStyle(foregroundStyle)
            .background(backgroundView)
            .contextMenu {
              Button("Copy", systemSymbol: .documentOnDocument) { onCopy?() }
            }
        }
        .padding(position == .leading ? .leading : .trailing)

        if position == .leading {
          Spacer(minLength: 60)
        }
      }
    } else {
      HStack {
        content()
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 15)
      .frame(minWidth: 40)
      .foregroundStyle(foregroundStyle)
      .background(backgroundView)
      .horizontalAlignment(position == .leading ? .leading : .trailing)
      .padding(.horizontal)
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
        .fill(backgroundStyle)
        .asAny
    } else {
      return ChatBubbleShape(tailPosition: tailPosition)
        .stroke(style: StrokeStyle(lineWidth: 3, dash: [4]))
        .fill(backgroundStyle)
        .background(
          ChatBubbleShape(tailPosition: tailPosition)
            .fill(backgroundStyle.opacity(0.3))
        )
        .asAny
    }
  }
}

struct ChatBubble_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      VStack(spacing: 8) {
        ChatBubble(position: .leading, showTail: true, backgroundStyle: .chatGrey) {
          Text("Hello World")
        }
        ChatBubble(position: .trailing, foregroundStyle: .white, backgroundStyle: .blue) {
          Text("Why hello")
        }
        ChatBubble(position: .trailing, showTail: true, foregroundStyle: .white, backgroundStyle: .blue) {
          Text("How are you doing?")
        }
        ChatBubble(position: .leading, showTail: true, backgroundStyle: .chatGrey) {
          Text("I'm doing great, this is a really great chat app don't you say?")
        }
        ChatBubble(position: .trailing, showTail: true, foregroundStyle: .white, backgroundStyle: .blue) {
          Text("Yes, it is certainly splendid. And it's built with no server!")
        }
        ChatBubble(position: .trailing, showTail: true, foregroundStyle: .white, backgroundStyle: .blue) {
          Text("I")
        }
        ChatBubble(position: .trailing, showTail: true, foregroundStyle: .white, backgroundStyle: .blue) {
          Text("🥳")
        }
        ChatBubble(position: .leading, showTail: true, shouldFill: false, backgroundStyle: .chatGrey) {
          Text("This is a secret direct message, don't tell anyone!")
        }
        ChatBubble(position: .trailing, showTail: true, shouldFill: false, backgroundStyle: .blue) {
          Text("OK I won't!")
        }
      }
    }
    .background(Color(uiColor: .systemBackground))
    //        .environment(\.colorScheme, .dark)
  }
}
