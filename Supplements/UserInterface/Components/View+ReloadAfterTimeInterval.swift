//
//  View+ReloadAfterTimeInterval.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-18.
//

import SwiftUI

struct ReloadAfterTimeInterval: ViewModifier {

    let timeInterval: TimeInterval

    @Environment(\.scenePhase) private var scenePhase
    @State private var dateOfLastAppearance: Date = .now

    func body(content: Content) -> some View {
        TimelineView(.everyMinute) { _ in
            content
                .onChange(of: scenePhase, initial: false) { _, newValue in
                    guard newValue == .active else { return }

                    if dateOfLastAppearance.timeIntervalSinceNow > timeInterval {
                        dateOfLastAppearance = .now
                    }
                }
                .id(dateOfLastAppearance)
        }
    }
}

extension View {

    func reload(after timeInterval: TimeInterval) -> some View {
        modifier(ReloadAfterTimeInterval(timeInterval: timeInterval))
    }
}
