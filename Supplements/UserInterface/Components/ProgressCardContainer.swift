//
//  ProgressCardContainer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-18.
//

import SwiftUI

extension View {

    func progressCardContainer<S, S2>(
        progress: Double,
        backgroundFill: S = BackgroundStyle.background.secondary,
        backgroundStroke: S2 = .clear,
        includePadding: Bool = true
    ) -> some View where S: ShapeStyle, S2: ShapeStyle {
        self
            .if(includePadding) {
                $0.padding()
            }
            .background {
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(.tint)
                            .frame(width: proxy.size.width * progress.clipped(0, 1))
                        Spacer(minLength: 0)
                    }
                }
                .compositingGroup()
                .clipShape(RoundedRectangle(cornerRadius: 26))
            }
            .cardContainer(
                fill: backgroundFill,
                stroke: backgroundStroke,
                includePadding: false
            )
            .animation(.bouncy, value: progress)
    }
}

#Preview {
    ScrollView {
        VStack {
            HStack {
                Spacer()
                Text("Hello\nWorld")
                Spacer()
            }
            .progressCardContainer(
                progress: 0.4
            )

            HStack {
                Label("Good Morning", systemImage: "sunrise.fill")

                Spacer()
            }
            .progressCardContainer(
                progress: 0.7
            )

            HStack {
                Label("Good Morning", systemImage: "sunrise.fill")

                Spacer()
            }
            .progressCardContainer(
                progress: 0.01
            )
        }
        .padding()
    }
}
