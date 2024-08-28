//
//  OnboardingCardTemplateView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI

struct OnboardingCardTemplateView<TopContent, BottomContent>: View where TopContent: View, BottomContent: View {

    let aspectRatio: CGFloat
    let topContent: TopContent
    let bottomContent: BottomContent

    init(
        aspectRatio: CGFloat = 1,
        @ViewBuilder card: () -> TopContent,
        @ViewBuilder bottom: () -> BottomContent
    ) {
        self.aspectRatio = aspectRatio
        self.topContent = card()
        self.bottomContent = bottom()
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.background.secondary)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay {
                    VStack {
                        topContent
                    }
                    .padding()
                }
                .background {
                    Rectangle()
                        .fill(.background.secondary)
                        .ignoresSafeArea()
                }
                .layoutPriority(100)

            VStack {
                bottomContent
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingCardTemplateView {
        Text("Hello World")
    } bottom: {
        ScrollView {
            VStack {
                Text("Hello Friend")
                    .cardContainer(fill: .background.secondary)
            }
            .padding()
            .horizontallyCentered()
        }
    }
}
