//
//  PaywallButtonStyle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct PaywallButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer(minLength: 0)
            configuration.label
            Spacer(minLength: 0)
        }
        .foregroundStyle(.invertedText)
        .tint(.invertedText)
        .bold()
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.tint)
        }
    }
}

extension ButtonStyle where Self == PaywallButtonStyle {
    static var paywall: some ButtonStyle { PaywallButtonStyle() }
}

#Preview {
    Button("Paywall") {

    }
    .buttonStyle(.paywall)
    .padding()
}
