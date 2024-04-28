//
//  View+RoundedBackground.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-04-28.
//

import SwiftUI

extension View {

    func roundedBackground() -> some View {
        self
            .padding(.vertical, 4)
            .padding(.horizontal)
            .background {
            RoundedRectangle(cornerRadius: 13)
                .fill(.background.secondary)
        }
    }
}
