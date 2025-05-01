//
//  CyclePhaseLearnMoreView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-24.
//

import SwiftUI
import TelemetryDeck
import CoreHealth

struct CyclePhaseLearnMoreView: View {
    let phase: MenstrualCyclePhase

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(phase.coolFacts) { coolFact in
                    CyclePhaseCoolFactCell(coolFact: coolFact)
                }
            }
            .padding()
            .horizontallyCentered()
        }
        .groupedBackground()
        .navigationTitle(phase.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            TelemetryDeck.viewScreen("Cycle Tracking Vital Details")
        }
        .tint(phase.color ?? .mutedIndigo)
    }
}

#Preview {
    NavigationStack {
        CyclePhaseLearnMoreView(phase: .luteal)
    }
}
