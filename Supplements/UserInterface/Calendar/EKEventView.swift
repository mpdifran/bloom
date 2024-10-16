//
//  EKEventView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-25.
//

import SwiftUI
import EventKit
import EventKitUI

struct EKEventView: UIViewControllerRepresentable {
    let event: EKEvent
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let eventViewController = EKEventViewController()
        eventViewController.event = event
        eventViewController.delegate = context.coordinator
        eventViewController.allowsEditing = true

        let navigationController = UINavigationController(rootViewController: eventViewController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: {
            dismiss()
        })
    }
}

extension EKEventView {
    final class Coordinator: NSObject, EKEventViewDelegate, Sendable {
        let onDismiss: @MainActor @Sendable () -> Void

        init(onDismiss: @escaping @MainActor @Sendable () -> Void) {
            self.onDismiss = onDismiss
        }

        func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
            MainTask { [weak self] in
                self?.onDismiss()
            }
        }
    }
}

#Preview {
    EKEventView(event: .preview)
        .task {
            await CalendarManager.shared.promptForPermission()
        }
}
