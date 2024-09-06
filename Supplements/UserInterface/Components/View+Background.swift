//
//  View+Background.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-04.
//

import SwiftUI

extension View {

    func groupedBackground() -> some View {
        background {
            Rectangle()
                .fill(.background.secondary)
                .ignoresSafeArea()
        }
    }

    func gradientRootBackground() -> some View {
        background {
            Rectangle()
                .fill(.background.secondary)
                .ignoresSafeArea()
                .overlay {
                    VStack {
                        LinearGradient(
                            colors: [
                                .vitalGreat.opacity(0.4),
                                .vitalGood.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 500)
                        .mask {
                            LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
                        }
                        
                        Spacer()
                    }
                    .ignoresSafeArea()
                }
        }
    }
}

#Preview("Gradient Root Background") {
    NavigationStack {
        ScrollView {
            VStack {
                Text("Hello World")
                    .horizontallyCentered()
                    .cardContainer()
            }
            .horizontallyCentered()
            .padding()
        }
        .gradientRootBackground()
        .navigationTitle("Today")
    }

}
