//
//  Chart+DateScale.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import Charts

extension View {

    @ViewBuilder
    func chartXScale(numDaysToNow: Int) -> some View {
        if let startDate = Calendar.current.date(byAdding: .day, value: -numDaysToNow, to: .now) {
            self.chartXScale(domain: startDate...Date.now, range: .plotDimension)
        } else {
            self
        }
    }
}
