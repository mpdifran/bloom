//
//  TertiaryButtonStyle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import SwiftUI

struct TertiaryButtonStyle: ButtonStyle {

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

extension ButtonStyle where Self == TertiaryButtonStyle {
    static var tertiary: some ButtonStyle { TertiaryButtonStyle() }
}

#Preview {
    Button("Tap Me", systemImage: "sparkles") {

    }
    .buttonStyle(.tertiary)
    .padding()
    .tint(.blue)
}
