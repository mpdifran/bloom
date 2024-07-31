//
//  CardContainer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI

extension View {

    func cardContainer() -> some View {
        self
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 30)
                    .fill(.background)
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
