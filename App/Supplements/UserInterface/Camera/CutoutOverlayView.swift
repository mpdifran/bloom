//
//  CutoutOverlayView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import SwiftUI

struct CutoutOverlayView: View {
    let aspectRatio: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Rectangle()
                        .fill(.tint.opacity(0.1))
                }

            RoundedRectangle(cornerRadius: 30)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .blendMode(.destinationOut)
                .overlay {
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(.tint, lineWidth: 6)
                }
                .padding(20)
        }
        .compositingGroup()
        .ignoresSafeArea()
    }
}

#Preview("Square") {
    CutoutOverlayView(aspectRatio: 1)
        .tint(.green)
}

#Preview("Tall") {
    CutoutOverlayView(aspectRatio: 0.6)
        .tint(.green)
}
