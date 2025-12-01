//
//  ChatWithBudIcon.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-01.
//

import SwiftUI
import BloomFoundation

private extension TimeInterval {
  static let animationDuration: TimeInterval = 0.8 // s
  static let onPause: TimeInterval = 3 // s
  static let offPause: TimeInterval = 0.5 // s
}

private extension Int {
  static let offsetDelay: Int = 500 // ms
}

struct ChatWithBudIcon: View {

  @State private var showChatBubble = false
  @State private var showResponseRect = false

  var body: some View {
    GeometryReader { proxy in
      RoundedRectangle(cornerRadius: outerCornerRadius(for: proxy))
        .fill(.background.secondary)
        .overlay {
          VStack(spacing: padding(for: proxy)) {

            if showChatBubble {
              ChatBubbleShape(tailPosition: .trailing)
                .foregroundStyle(.blue)
                .frame(width: 60, height: 40)
                .scaleEffect(x: bubbleScale(for: proxy), y: bubbleScale(for: proxy), anchor: .center)
                .frame(width: 60 * bubbleScale(for: proxy), height: 40 * bubbleScale(for: proxy))
                .horizontalAlignment(.trailing)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            Spacer(minLength: 0)

            if showResponseRect {
              RoundedRectangle(cornerRadius: innerCornerRadius(for: proxy))
                .fill(.fill)
                .transition(.scale(scale: 0.1, anchor: .bottom).combined(with: .opacity))
            }
          }
          .padding(padding(for: proxy))
          .horizontallyCentered()
          .clipShape(RoundedRectangle(cornerRadius: outerCornerRadius(for: proxy)))
        }
        .clipped()
    }
    .aspectRatio(6/7, contentMode: .fit)
    .animation(.bouncy(duration: .animationDuration), value: showChatBubble)
    .animation(.bouncy(duration: .animationDuration), value: showResponseRect)
    .task {
      await runAnimationLoop()
    }
  }
}

private extension ChatWithBudIcon {

  func outerCornerRadius(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 6
  }

  func padding(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 20
  }

  func bubbleScale(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 100
  }

  func bubbleLength(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width * 0.8
  }

  func bubbleHeight(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width * 0.5
  }

  func innerCornerRadius(for proxy: GeometryProxy) -> CGFloat {
    outerCornerRadius(for: proxy) - padding(for: proxy)
  }

  func innerRectHeight(for proxy: GeometryProxy) -> CGFloat {
    (proxy.size.height - 4 * padding(for: proxy)) / 3
  }

  func animationDistance(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 6
  }
}

private extension ChatWithBudIcon {

  func runAnimationLoop() async {
    while true {
      await animateSequenceIn()
      try? await Task.sleep(for: .seconds(.onPause))
      await animateSequenceOut()
      try? await Task.sleep(for: .seconds(.offPause))
    }
  }

  func animateSequenceIn() async {
    showChatBubble = true
    await Delay(.offsetDelay)
    showResponseRect = true
  }

  func animateSequenceOut() async {
    showResponseRect = false
    await Delay(.offsetDelay)
    showChatBubble = false
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ChatWithBudIcon()
        .frame(width: 80)

      ChatWithBudIcon()
        .frame(width: 40)

      ChatWithBudIcon()
        .frame(width: 120)
    }
  }
}
