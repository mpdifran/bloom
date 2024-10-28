//
//  View+AppearWithIndex.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-25.
//

import SwiftUI

extension View {

    @ViewBuilder
    func appear(with index: Int, currentIndex: Int, secondaryIfNotCurrentIndex: Bool = true) -> some View {
        if index <= currentIndex {
            self
                .if(currentIndex != index && secondaryIfNotCurrentIndex) {
                    $0.foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
