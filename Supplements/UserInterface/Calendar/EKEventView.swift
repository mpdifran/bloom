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
        Coordinator(dismiss: dismiss)
    }
}

extension EKEventView {
    class Coordinator: NSObject, EKEventViewDelegate {
        var dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
            dismiss()
        }
    }
}

#Preview {
    EKEventView(event: .preview)
        .task {
            await CalendarManager.shared.promptForPermission()
        }
}
