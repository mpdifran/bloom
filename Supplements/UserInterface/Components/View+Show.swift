//
//  View+Show.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-25.
//

import SwiftUI

struct ViewShowModifier: ViewModifier {

    let action: () -> Void

    private let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

    func body(content: Content) -> some View {
        content
            .onAppear {
                action()
            }
            .onReceive(foregroundPublisher) { _ in
                action()
            }
    }
}

extension View {

    func onShow(perform action: @escaping () -> Void) -> some View {
        modifier(ViewShowModifier(action: action))
    }
}
