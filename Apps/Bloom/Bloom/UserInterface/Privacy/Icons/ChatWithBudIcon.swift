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
  let isEnabled: Bool

  @State private var showChatBubble = true
  @State private var showResponseRect = true

  var body: some View {
    GeometryReader { proxy in
      RoundedRectangle(cornerRadius: outerCornerRadius(for: proxy))
        .fill(.background.secondary)
        .overlay {
          VStack(spacing: padding(for: proxy)) {

            if showChatBubble {
              ChatBubbleShape(tailPosition: .trailing)
                .foregroundStyle(.mutedLightBlue)
                .frame(width: 70, height: 40)
                .scaleEffect(x: bubbleScale(for: proxy), y: bubbleScale(for: proxy), anchor: .center)
                .frame(width: 70 * bubbleScale(for: proxy), height: 40 * bubbleScale(for: proxy))
                .horizontalAlignment(.trailing)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            Spacer(minLength: 0)

            if showResponseRect {
              RoundedRectangle(cornerRadius: innerCornerRadius(for: proxy))
                .fill(.fill)
                .transition(.scale(scale: 0.1, anchor: .leading).combined(with: .opacity))
            }
          }
          .padding(padding(for: proxy))
          .horizontallyCentered()
          .clipShape(RoundedRectangle(cornerRadius: outerCornerRadius(for: proxy)))
        }
        .clipped()
    }
    .aspectRatio(6/9, contentMode: .fit)
    .saturation(isEnabled ? 1 : 0)
    .animation(.bouncy(duration: .animationDuration), value: showChatBubble)
    .animation(.bouncy(duration: .animationDuration), value: showResponseRect)
    .animation(.default, value: isEnabled)
    .onChange(of: isEnabled) { oldValue, newValue in
      if newValue {
        Task {
          await runAnimationLoop()
        }
      } else {
        showChatBubble = true
        showResponseRect = true
      }
    }
    .onAppear {
      Task {
        await runAnimationLoop()
      }
    }
  }
}

private extension ChatWithBudIcon {

  func outerCornerRadius(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 4
  }

  func padding(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 10
  }

  func bubbleScale(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 100
  }

  func innerCornerRadius(for proxy: GeometryProxy) -> CGFloat {
    outerCornerRadius(for: proxy) - padding(for: proxy)
  }
}

private extension ChatWithBudIcon {

  func runAnimationLoop() async {
    while isEnabled {
      await animateSequenceOut()
      try? await Task.sleep(for: .seconds(.offPause))
      await animateSequenceIn()
      try? await Task.sleep(for: .seconds(.onPause))
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
      ChatWithBudIcon(isEnabled: true)
        .frame(width: 40)

      ChatWithBudIcon(isEnabled: false)
        .frame(width: 80)

      ChatWithBudIcon(isEnabled: true)
        .frame(width: 120)
    }
  }
}
