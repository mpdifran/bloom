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

    func onForeground(_ onForeground: @escaping () -> Void) -> some View {
        modifier(OnForegroundModifier(onForeground: onForeground))
    }
}
