//
//  CompletionCheckmarkView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import SwiftUI

extension CompletionCheckmarkView {
    enum State {
        case unmetGoal
        case metGoal
        case exceededGoal
    }
}

struct CompletionCheckmarkView: View {
    let state: State

    var body: some View {
        Group {
            switch state {
            case .unmetGoal:
                Image(systemName: "circle")
                    .foregroundStyle(.fill)
            case .metGoal:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint, .white)
            case .exceededGoal:
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.tint, .white)
                    .background {
                        Circle()
                            .fill(.white.tertiary)
                    }
            }
        }
        .font(.title)
        .contentTransition(.symbolEffect)
        .animation(.bouncy, value: state)
    }
}

#Preview {
    VStack {
        CompletionCheckmarkView(state: .unmetGoal)
        CompletionCheckmarkView(state: .metGoal)
        CompletionCheckmarkView(state: .exceededGoal)
    }
    .tint(.mutedGreen)
}
