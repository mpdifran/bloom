//
//  View+Foreground.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-04.
//

import SwiftUI

struct OnForegroundModifier: ViewModifier {

  let onForeground: () -> Void

  private let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

  func body(content: Content) -> some View {
    content.onReceive(foregroundPublisher) { _ in
      onForeground()
    }
  }
}

extension View {

  /// Calls ``onForeground`` whenever the app enters the foreground. This is not called on app launch.
  func onForeground(_ onForeground: @escaping () -> Void) -> some View {
    modifier(OnForegroundModifier(onForeground: onForeground))
  }
}

struct OnForegroundTaskModifier: ViewModifier {

  let onForegroundTask: () async -> Void

  private let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

  func body(content: Content) -> some View {
    content
      .onReceive(foregroundPublisher) { _ in
        Task {
          await onForegroundTask()
        }
      }
      .task {
        await onForegroundTask()
      }
  }
}

extension View {

  /// Schedules a .task on this view, while also calling ``onForegroundTask`` any time the app enters the foreground.
  func onForegroundTask(_ onForegroundTask: @escaping () async -> Void) -> some View {
    modifier(OnForegroundTaskModifier(onForegroundTask: onForegroundTask))
  }
}
