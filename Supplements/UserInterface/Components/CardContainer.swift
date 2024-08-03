//
//  CardContainer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI

extension View {

    func cardContainer<S>(fill: S = BackgroundStyle.background) -> some View where S: ShapeStyle {
        self
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 30)
                    .fill(fill)
            }
    }
}

#Preview {
    ScrollView {
        HStack {
            Spacer()
            Text("Hello\nWorld")
            Spacer()
        }
        .cardContainer()
        .padding()
    }
    .background {
        Rectangle()
            .fill(.background.secondary)
            .ignoresSafeArea()
    }
}
