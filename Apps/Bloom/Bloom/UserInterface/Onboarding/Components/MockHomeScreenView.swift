//
//  MockHomeScreenView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-28.
//

import SwiftUI

private extension CGFloat {
    static let appSpacing: CGFloat = 20
}

struct MockHomeScreenView: View {
    var body: some View {
        VStack(spacing: .appSpacing) {
            Capsule()
                .fill(.background.secondary)
                .frame(width: 100, height: 30)

            HStack(spacing: .appSpacing) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .frame(square: 120)

                makeAppBlock()
            }

            HStack(spacing: .appSpacing) {
                makeAppBlock()
                makeAppBlock()
            }

            HStack(spacing: .appSpacing) {
                makeAppBlock()
                makeAppBlock()
            }

            Spacer()

            RoundedRectangle(cornerRadius: 30)
                .fill(.thinMaterial)
                .frame(height: 80)
        }
        .frame(width: 280, height: 600)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [
                            .mutedIndigo,
                            .mutedPink,
                            .mutedOrange
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 56)
                .fill(.background.secondary)
        }
    }
}

extension MockHomeScreenView {

    func makeAppBlock() -> some View {
        VStack(spacing: .appSpacing) {
            HStack(spacing: .appSpacing) {
                makeApp()
                makeApp()
            }

            HStack(spacing: .appSpacing) {
                makeApp()
                makeApp()
            }
        }
    }

    func makeApp() -> some View {
        RoundedRectangle(cornerRadius: 13)
            .fill(.ultraThinMaterial)
            .frame(square: 50)
    }
}

#Preview {
    MockHomeScreenView()
}
