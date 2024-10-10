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
        .animation(.bouncy(duration: 0.7).delay(0.5), value: showContinueButton)
        .onAppear {
            showContinueButton = true
        }
    }
}

private extension BloomPlusPaywall {

    var contentView: some View {
        VStack {
            VStack(spacing: 30) {
                BloomPlusFeaturesListView()

                Divider()

                BloomPlusUserReviewListView()

                Divider()

                BloomPlusLegalSectionView()
            }
            .padding()
            .padding(.top)
        }
    }

    var purchaseShelf: some View {
        VStack {
            Button {

            } label: {
                Text("Continue")
            }
            .buttonStyle(.paywall)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(.thinMaterial)
                .shadow(color: .mutedBlue.opacity(0.4), radius: 30)
        }
        .padding()
        .transition(.move(edge: .bottom))
    }
}

#Preview {
    BloomPlusPaywall()
}
