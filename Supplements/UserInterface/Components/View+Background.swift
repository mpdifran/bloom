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
}
