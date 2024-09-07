//
//  View+Confetti.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SwiftUI
import ConfettiSwiftUI

extension View {

    func standardConfetti(_ counter: Binding<Int>, colors: [Color]) -> some View {
        confettiCannon(
            counter: counter,
            num: 150,
            colors: colors,
            confettiSize: 15,
            openingAngle: .init(degrees: 0),
            closingAngle: .init(degrees: 360),
            radius: 250
        )
    }
}
