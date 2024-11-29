//
//  SleepProgressRingView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SwiftUI

private extension CGFloat {
    static let dimension: CGFloat = 40
    static let ringShift: CGFloat = 32
}

struct SleepProgressRingView: View {
    @Binding var remSleepPercentage: CGFloat
    @Binding var coreSleepPercentage: CGFloat
    @Binding var deepSleepPercentage: CGFloat

    var body: some View {
        ZStack {
            ProgressRingView(
                progress: $remSleepPercentage,
                dimension: .dimension + .ringShift * 2,
                color: .remSleep
            )

            ProgressRingView(
                progress: $coreSleepPercentage,
                dimension: .dimension + .ringShift,
                color: .coreSleep
            )

            ProgressRingView(
                progress: $deepSleepPercentage,
                dimension: .dimension,
                color: .deepSleep
            )
        }
    }
}

#Preview {
    SleepProgressRingView(
        remSleepPercentage: .constant(1),
        coreSleepPercentage: .constant(1),
        deepSleepPercentage: .constant(1)
    )
}
