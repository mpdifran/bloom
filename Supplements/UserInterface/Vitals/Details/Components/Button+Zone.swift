//
//  Button+Zone.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-11.
//

import SwiftUI

struct ZoneButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
        }
        .bold()
        .foregroundStyle(.invertedText)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.tint)
        }
    }
}

extension ButtonStyle where Self == ZoneButtonStyle {
    static var zone: some ButtonStyle { ZoneButtonStyle() }
}

#Preview {
    Button {

    } label: {
        HStack {
            Text("Tap Me")

            Spacer()

            Image(systemName: "sparkles")
        }
    }
    .buttonStyle(.zone)
    .tint(.blue)
    .padding()
}
