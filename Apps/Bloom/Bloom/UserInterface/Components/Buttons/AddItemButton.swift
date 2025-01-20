//
//  AddItemButton.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-27.
//

import SwiftUI

struct AddItemButton: View {
    let hasAdded: Bool
    let toggleAdd: () -> Void

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            toggleAdd()
        }, label: {
            Image(systemName: hasAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                .foregroundStyle(.white, .tint)
                .font(.largeTitle)
                .fontDesign(.rounded)
                .contentTransition(.symbolEffect)
        })
    }
}

#Preview {
    VStack {
        AddItemButton(hasAdded: true) { }
        AddItemButton(hasAdded: false) { }
    }
}
