//
//  FoodSearchToolCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-08.
//

import SwiftUI

struct FoodSearchToolCell: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(title)
        }
        .bold()
        .foregroundStyle(.tint)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.tint.quinary)
        }
    }
}

#Preview {
    FoodSearchToolCell(
        title: "Scan",
        systemImage: "barcode.viewfinder"
    )
    FoodSearchToolCell(
        title: "AI Photo",
        systemImage: "camera.viewfinder"
    )
}
