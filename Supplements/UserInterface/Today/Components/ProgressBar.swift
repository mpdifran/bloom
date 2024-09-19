//
//  ProgressBar.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import SwiftUI

struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            shape
                .fill(.fill)
                .overlay {
                    HStack(spacing: 0) {
                        shape
                            .fill(.tint)
                            .frame(width: proxy.size.width * clampedProgress)
                        Spacer(minLength: 0)
                    }
                }
        }
        .frame(height: 8)
        .animation(.bouncy, value: progress)
    }
}

private extension ProgressBar {

    var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var shape: some Shape {
        Capsule()
//        RoundedRectangle(cornerRadius: 5)
    }
}

#Preview {
    VStack {
        ProgressBar(progress: 0)
        ProgressBar(progress: 0.2)
        ProgressBar(progress: 0.6)
        ProgressBar(progress: 1)
        ProgressBar(progress: 1.5)
    }
    .padding()
    .tint(.mutedPink)
}
