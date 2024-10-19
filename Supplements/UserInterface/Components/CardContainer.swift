//
//  CardContainer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import AppUI

extension View {

    func cardContainer<S, S2>(
        fill: S = BackgroundStyle.background,
        stroke: S2 = .clear,
        includePadding: Bool = true
    ) -> some View where S: ShapeStyle, S2: ShapeStyle {
        self
            .if(includePadding) {
                $0.padding()
            }
            .background {
                RoundedRectangle(cornerRadius: 26)
                    .fill(fill)
                    .overlay {
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(stroke, lineWidth: 1)
                    }
            }
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
            .cardContainer()

            HStack {
                Label("Good Morning", systemImage: "sunrise.fill")
                    .foregroundStyle(.mutedGreen)

                Spacer()
            }
            .cardContainer(fill: .mutedGreen.opacity(0.3), stroke: .mutedGreen)
        }
        .padding()
    }
    .groupedBackground()
}
