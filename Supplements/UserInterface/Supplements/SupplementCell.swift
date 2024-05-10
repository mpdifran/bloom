//
//  SupplementCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct SupplementCell: View {
    let supplement: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(supplement)
                .bold()

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .contentTransition(.symbolEffect)
                .imageScale(.large)
                .foregroundStyle(.tint)
        }
        .fontDesign(.rounded)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        SupplementCell(supplement: "Vitamin C", isSelected: true)
    }
}
