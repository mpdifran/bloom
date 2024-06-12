//
//  SymptomCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-12.
//

import SwiftUI

struct SymptomCell: View {
    let symptom: String
    let isSelected: Bool

    var body: some View {
        Text(symptom)
            .multilineTextAlignment(.center)
            .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AnyShapeStyle(.tint.opacity(0.3)) : AnyShapeStyle(BackgroundStyle.background.secondary))
            }
            .animation(.default, value: isSelected)
    }
}

#Preview {
    LazyVGrid(columns: [.init(.flexible(minimum: 60))]) {
        SymptomCell(symptom: "Groggy", isSelected: false)
        SymptomCell(symptom: "Well Rested", isSelected: true)
    }
}
