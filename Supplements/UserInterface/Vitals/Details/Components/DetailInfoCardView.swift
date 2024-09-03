//
//  DetailInfoCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-11.
//

import SwiftUI

struct DetailInfoCardView<Content>: View where Content: View {
    let content: Content

    init(@ViewBuilder _ contentBuilder: () -> Content) {
        self.content = contentBuilder()
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 15) {
                Text("Details")
                    .font(.headline)
                    .bold()

                content
            }
            Spacer(minLength: 0)
        }
        .cardContainer(fill: .background.secondary)
    }
}

#Preview {
    DetailInfoCardView {
        Text("This is some information presented in the card.")
    }
    .padding()
}
