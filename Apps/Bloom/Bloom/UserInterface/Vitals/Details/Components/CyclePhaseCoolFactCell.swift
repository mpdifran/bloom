//
//  CyclePhaseCoolFactCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-24.
//

import SwiftUI
import CoreHealth

struct CyclePhaseCoolFactCell: View {
    let coolFact: MenstrualCyclePhase.CoolFact

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(coolFact.title)
                .font(.title3)
                .bold()
                .foregroundStyle(.tint)

            Text(coolFact.fact)
        }
        .cardContainer()
    }
}

#Preview {
    VStack {
        Spacer()
        CyclePhaseCoolFactCell(
            coolFact: MenstrualCyclePhase.luteal.coolFacts[0]
        )
        Spacer()
    }
    .padding()
    .groupedBackground()
}
