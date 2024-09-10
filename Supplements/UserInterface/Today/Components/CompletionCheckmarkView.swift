//
//  CompletionCheckmarkView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import SwiftUI

struct CompletionCheckmarkView: View {
    let hasCompleted: Bool

    var body: some View {
        Group {
            if hasCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, .tint)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.fill)
            }
        }
        .font(.title)
        .contentTransition(.symbolEffect)
        .animation(.bouncy, value: hasCompleted)
    }
}

#Preview {
    VStack {
        CompletionCheckmarkView(hasCompleted: true)
        CompletionCheckmarkView(hasCompleted: false)
    }
    .tint(.mutedPink)
}
