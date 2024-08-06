//
//  CardContainer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import AppUI

extension View {

    func cardContainer<S>(fill: S = BackgroundStyle.background, includePadding: Bool = true) -> some View where S: ShapeStyle {
        self
            .if(includePadding) {
                $0.padding()
            }
            .background {
                RoundedRectangle(cornerRadius: 20)
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
    .groupedBackground()
}
