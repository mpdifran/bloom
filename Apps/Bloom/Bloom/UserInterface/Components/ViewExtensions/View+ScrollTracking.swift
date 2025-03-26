//
//  View+ScrollTracking.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import SwiftUI
import Combine

extension View {

  func onScrollEnded(
    in coordinateSpace: CoordinateSpace,
    onScrollEnded: @escaping (CGFloat) -> Void
  ) -> some View {
    modifier(
      OnHorizontalScrollEnded(
        coordinateSpace: coordinateSpace,
        scrollPostionUpdate: onScrollEnded
      )
    )
  }
}

private struct HorizontalScrollOffsetKey: PreferenceKey {
  static let defaultValue = CGFloat.zero

  static func reduce(value: inout Value, nextValue: () -> Value) {
    value += nextValue()
  }
}

private final class OnHorizontalScrollEndedOffsetTracker: ObservableObject {
  let scrollViewHorizontalOffset = CurrentValueSubject<CGFloat, Never>(0)

  func updateOffset(_ offset: CGFloat) {
    scrollViewHorizontalOffset.send(offset)
  }
}

private struct OnHorizontalScrollEnded: ViewModifier {
  let coordinateSpace: CoordinateSpace
  let scrollPostionUpdate: (CGFloat) -> Void
  @StateObject private var offsetTracker = OnHorizontalScrollEndedOffsetTracker()

  func body(content: Content) -> some View {
    content
      .backgroundPreference(key: HorizontalScrollOffsetKey.self, valueBuilder: { proxy in
        abs(proxy.frame(in: coordinateSpace).origin.x)
      })
//      .background(
//        GeometryReader(content: { geometry in
//          Color.clear.preference(key: HorizontalScrollOffsetKey.self, value: abs(geometry.frame(in: coordinateSpace).origin.y))
//        })
//      )
      .onPreferenceChange(HorizontalScrollOffsetKey.self) { offset in
        MainTask {
          offsetTracker.updateOffset(offset)
        }
      }
      .onReceive(
        offsetTracker
          .scrollViewHorizontalOffset
          .debounce(for: 0.1, scheduler: DispatchQueue.main)
          .dropFirst(),
        perform: scrollPostionUpdate
      )
  }
}
