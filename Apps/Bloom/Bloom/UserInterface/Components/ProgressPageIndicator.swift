//
//  ProgressPageIndicator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-10.
//

import SwiftUI

private extension CGFloat {
  static let expandedWidth: CGFloat = 40
  static let dimension: CGFloat = 10
  static let spacing: CGFloat = 8
}

struct ProgressPageIndicator: View {
  let pageDuration: TimeInterval
  let currentPage: Int
  let numberOfPages: Int

  @State private var progress: CGFloat = 0
  @State private var elapsed: TimeInterval = 0
  private let tickInterval: TimeInterval = 0.1
  @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
  
  private var clampedCurrentPage: Int {
    max(0, min(currentPage, numberOfPages - 1))
  }

  var body: some View {
    HStack(spacing: .spacing) {
      ForEach(0..<numberOfPages, id: \.self) { pageIndex in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(.fill)
            .frame(
              width: pageIndex == clampedCurrentPage ? .expandedWidth : .dimension,
              height: .dimension
            )

          Capsule()
            .fill(.tint)
            .opacity(pageIndex == clampedCurrentPage ? 1 : 0)
            .frame(
              width: pageIndex == clampedCurrentPage ? (.expandedWidth - .dimension) * max(0, min(1, progress)) + .dimension : .dimension,
              height: .dimension
            )
        }
        .animation(.bouncy(duration: 0.5), value: clampedCurrentPage)
      }
    }
    .onReceive(timer) { _ in
      let duration = max(0.01, pageDuration)
      elapsed += tickInterval
      let newProgress = min(1, max(0, elapsed / duration))
      withAnimation(.linear(duration: tickInterval)) {
        progress = newProgress
      }
    }
    .onChange(of: clampedCurrentPage) { _, _ in
      // Reset progress when page changes
      elapsed = 0
      progress = 0
      // restart timer connection
      timer = Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()
    }
    .onAppear {
      elapsed = 0
      progress = 0
      timer = Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()
    }
    .onDisappear {
      // Stop timer when not visible
      timer.upstream.connect().cancel()
    }
  }
}

#Preview {
  @Previewable @State var currentPage: Int = 0
  let pageDuration: TimeInterval = 5.0
  let numberOfPages = 5

  VStack {
    ProgressPageIndicator(
      pageDuration: pageDuration,
      currentPage: currentPage,
      numberOfPages: numberOfPages
    )
  }
  .onAppear {
    Timer.scheduledTimer(withTimeInterval: pageDuration, repeats: true) { _ in
      withAnimation(.bouncy) {
        currentPage = (currentPage + 1) % numberOfPages
      }
    }
  }
}
