//
//  TodayInsightsIcon.swift
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
  static let offsetDelay: Int = 100 // ms
}

struct TodayInsightsIcon: View {
  @State private var showTop = true
  @State private var showMiddleLeft = true
  @State private var showMiddleRight = true
  @State private var showBottom = true
  @State private var isAnimatingOut = false

  var body: some View {
    GeometryReader { proxy in
      RoundedRectangle(cornerRadius: outerCornerRadius(for: proxy))
        .fill(.background.secondary)
        .overlay {
          VStack(spacing: internalPadding(for: proxy)) {
            RoundedRectangle(cornerRadius: innerCornerRadius(for: proxy))
              .fill(.mutedOrange.gradient)
              .frame(height: innerRectHeight(for: proxy))
              .opacity(showTop ? 1 : 0)
              .offset(y: showTop ? 0 : (isAnimatingOut ? -animationDistance(for: proxy) : animationDistance(for: proxy)))

            HStack(spacing: internalPadding(for: proxy)) {
              RoundedRectangle(cornerRadius: innerCornerRadius(for: proxy))
                .fill(LinearGradient(colors: [.mutedPurple, .mutedPink], startPoint: .bottom, endPoint: .top))
                .frame(height: innerRectHeight(for: proxy))
                .opacity(showMiddleLeft ? 1 : 0)
                .offset(y: showMiddleLeft ? 0 : (isAnimatingOut ? -animationDistance(for: proxy) : animationDistance(for: proxy)))

              RoundedRectangle(cornerRadius: innerCornerRadius(for: proxy))
                .fill(LinearGradient(colors: [.mutedBlue, .mutedGreen], startPoint: .bottomLeading, endPoint: .topTrailing))
                .frame(height: innerRectHeight(for: proxy))
                .opacity(showMiddleRight ? 1 : 0)
                .offset(y: showMiddleRight ? 0 : (isAnimatingOut ? -animationDistance(for: proxy) : animationDistance(for: proxy)))
            }

            RoundedRectangle(cornerRadius: innerCornerRadius(for: proxy))
              .fill(.mutedIndigo.gradient)
              .frame(height: innerRectHeight(for: proxy))
              .opacity(showBottom ? 1 : 0)
              .offset(y: showBottom ? 0 : (isAnimatingOut ? -animationDistance(for: proxy) : animationDistance(for: proxy)))
          }
          .padding(padding(for: proxy))
          .onAppear {
            Task {
              await runAnimationLoop()
            }
          }
        }
        .clipped()
    }
    .aspectRatio(6/9, contentMode: .fit)
  }
}

private extension TodayInsightsIcon {

  func outerCornerRadius(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 6
  }

  func padding(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 10
  }

  func internalPadding(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 18
  }

  func innerCornerRadius(for proxy: GeometryProxy) -> CGFloat {
    outerCornerRadius(for: proxy) - padding(for: proxy)
  }

  func innerRectHeight(for proxy: GeometryProxy) -> CGFloat {
    (proxy.size.height - 2 * padding(for: proxy) - 2 * internalPadding(for: proxy)) / 3
  }

  func animationDistance(for proxy: GeometryProxy) -> CGFloat {
    proxy.size.width / 6
  }

  func runAnimationLoop() async {
    while true {
      await animateSequenceOut()
      try? await Task.sleep(for: .seconds(.offPause))
      await animateSequenceIn()
      try? await Task.sleep(for: .seconds(.onPause))
    }
  }

  func animateSequenceIn() async {
    isAnimatingOut = false
    withAnimation(.bouncy(duration: .animationDuration)) { showTop = true }
    await Delay(.offsetDelay)
    withAnimation(.bouncy(duration: .animationDuration)) { showMiddleLeft = true }
    await Delay(.offsetDelay)
    withAnimation(.bouncy(duration: .animationDuration)) { showMiddleRight = true }
    await Delay(.offsetDelay)
    withAnimation(.bouncy(duration: .animationDuration)) { showBottom = true }
  }

  func animateSequenceOut() async {
    isAnimatingOut = true
    withAnimation(.bouncy(duration: .animationDuration)) { showTop = false }
    await Delay(.offsetDelay)
    withAnimation(.bouncy(duration: .animationDuration)) { showMiddleLeft = false }
    await Delay(.offsetDelay)
    withAnimation(.bouncy(duration: .animationDuration)) { showMiddleRight = false }
    await Delay(.offsetDelay)
    withAnimation(.bouncy(duration: .animationDuration)) { showBottom = false }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      TodayInsightsIcon()
        .frame(width: 40)

      TodayInsightsIcon()
        .frame(width: 80)

      TodayInsightsIcon()
        .frame(width: 120)
    }
  }
}
