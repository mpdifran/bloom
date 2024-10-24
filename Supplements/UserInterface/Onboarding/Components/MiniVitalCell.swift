//
//  MiniVitalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-23.
//

import SwiftUI
import DataContainer

struct MiniVitalCell: View {
    let vital: VitalModel

    var body: some View {
        HStack {
            Image(systemName: vital.id.systemImage)
                .bold()
                .font(.title3)
                .fontDesign(.rounded)
                .frame(width: 30)

            Text(vital.id.name)
                .bold()
                .font(.subheadline)
                .fontDesign(.rounded)

            Spacer()

            Text(vital.status)
                .font(.subheadline)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(.tint)
                .contentTransition(.interpolate)

            if let barLevel = vital.barLevel {
                VitalStatusBarView(
                    level: .init(barLevel: barLevel.level),
                    levelPercent: barLevel.proportion
                )
            }
        }
        .tint(vital.color)
        .cardContainer(fill: .background.secondary)
    }
}

#Preview {
    MiniVitalCell(
        vital: .init(
            id: .sleepQuality,
            subtitle: "45% Core\n12% Deep",
            status: "Good",
            color: .vitalGreat,
            barLevel: .init(level: .optimal, proportion: 0.9),
            hasNoData: false
        )
    )
}
