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
            ScrollView {
                contentView
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

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
            BloomPlusPaywallHeroImageView()

            VStack(spacing: 30) {
                BloomPlusFeaturesListView()

                Divider()

                BloomPlusUserReviewListView()

                Divider()

                BloomPlusLegalSectionView()
            }
            .padding()
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
