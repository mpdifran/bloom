//
//  DirectiveCompleteButton.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-23.
//

import SwiftUI

struct DirectiveCompleteButton: View {
    let title: String
    let isComplete: Bool
    let action: () -> Void

    init(
        _ title: String,
        isComplete: Bool,
        _ action: @escaping () -> Void
    ) {
        self.title = title
        self.isComplete = isComplete
        self.action = action
    }

    var body: some View {
        Button(
            action: {
                action()
            },
            label: {
                HStack {
                    Label(
                        title: {
                            Text(title)
                        },
                        icon: {
                            Image(systemName: "checkmark.circle")
                                .symbolVariant(isComplete ? .fill : .none)
                                .contentTransition(.symbolEffect)
                                .foregroundStyle(.white, .tint)
                        }
                    )
                    Spacer()
                }
            }
        )
        .bold()
        .frame(height: 44)
        .foregroundStyle(.tint)
        .animation(.bouncy, value: isComplete)
    }
}

#Preview {
    List {
        DirectiveCompleteButton("Mark as Taken", isComplete: false) {

        }
        DirectiveCompleteButton("Mark as Taken", isComplete: true) {

        }
    }
}
