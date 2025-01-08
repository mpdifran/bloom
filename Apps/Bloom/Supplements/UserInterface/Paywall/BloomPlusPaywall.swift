//
//  BloomPlusPaywall.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI
import AppUI

struct BloomPlusPaywall: View {

    @State private var showContinueButton = false

    var body: some View {
        ZStack {
            BloomPlusPaywallHeroImageView()
                .zStackAlignment(.top)
                .ignoresSafeArea(edges: .top)

            ScrollView {
                contentView
                    .background {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.background)
                    }
                    .padding(.top, 170)
            }
            .scrollIndicators(.hidden)

            BloomPlusHeaderView()
                .padding(.horizontal)
                .zStackAlignment(.top)
        }
        .safeAreaInset(edge: .bottom) {
            if showContinueButton {
                purchaseShelf
            }
        }
        .presentationCompactAdaptation(.fullScreenCover)
        .animation(.bouncy(duration: 0.7).delay(0.5), value: showContinueButton)
        .onAppear {
            showContinueButton = true
        }
    }
}

private extension BloomPlusPaywall {

    var contentView: some View {
        VStack {
            BloomPlusFeaturesListView()
                .padding(.top)
                .padding(.top)

            VStack(spacing: 30) {
                BloomPlusUserReviewListView()
                BloomPlusLegalSectionView()
            }
            .padding()
        }
    }

    var purchaseShelf: some View {
        VStack {
            Button {

            } label: {
                Text("Start Free Trial")
            }
            .buttonStyle(.paywall)

            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.white, .mutedGreen)
                Text("No Payment Now")
            }
            .font(.subheadline)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(.thickMaterial)
        }
        .padding()
        .transition(.move(edge: .bottom))
    }
}

#Preview {
    BloomPlusPaywall()
}
