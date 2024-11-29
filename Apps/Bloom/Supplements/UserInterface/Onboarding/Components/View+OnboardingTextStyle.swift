//
//  View+OnboardingTextStyle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-28.
//

import SwiftUI

extension View {

    func onboardingTextStyle() -> some View {
        self
            .font(.title)
            .bold()
            .fontDesign(.rounded)
    }
}
