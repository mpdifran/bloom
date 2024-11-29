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
            num: 70,
            colors: colors,
            confettiSize: 10,
            rainHeight: 600,
            openingAngle: .init(degrees: 20),
            closingAngle: .init(degrees: 160),
            radius: 320,
            repetitions: 0
        )
    }
}
