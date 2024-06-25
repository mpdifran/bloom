//
//  DirectiveCompleteButton.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-23.
//

import SwiftUI

struct DirectiveCompleteButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, _ action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: {
            action()
        },
               label: {
            HStack {
                Label(
                    title: {
                        Text(title)
                    },
                    icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white, .tint)
                    }
                )
                Spacer()
            }
        })
        .bold()
        .frame(height: 44)
        .foregroundStyle(.tint)
    }
}

#Preview {
    List {
        DirectiveCompleteButton("Mark as Taken") {

        }
    }
}
