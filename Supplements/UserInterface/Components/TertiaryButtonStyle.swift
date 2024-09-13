//
//  TertiaryButtonStyle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
        }
        .bold()
        .padding(.vertical, 16)
        .padding(.horizontal)
        .background(.tint.opacity(0.5))
        .foregroundStyle(.tint)
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: some ButtonStyle { PrimaryButtonStyle() }
}

#Preview {
    Button("Tap Me", systemImage: "sparkles") {

    }
    .buttonStyle(.primary)
    .padding()
    .tint(.blue)
}
