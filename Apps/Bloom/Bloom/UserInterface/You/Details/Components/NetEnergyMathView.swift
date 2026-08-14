//
//  NetEnergyMathView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-06.
//

import SwiftUI

struct NetEnergyMathView: View {
    let basalEnergy: Double
    let activeEnergy: Double
    let dietaryEnergy: Double
    let netEnergy: Double

    var body: some View {
        HStack {
            EnergyLabelView(energy: dietaryEnergy, name: "Dietary")
            Spacer()
            Text("-")
                .foregroundStyle(.secondary)
            Spacer()
            EnergyLabelView(energy: basalEnergy, name: "Basal")
            Spacer()
            Text("-")
                .foregroundStyle(.secondary)
            Spacer()
            EnergyLabelView(energy: activeEnergy, name: "Active")
            Spacer()
            Text("=")
                .foregroundStyle(.secondary)
            Spacer()
            EnergyLabelView(energy: netEnergy, name: "Net Energy")
        }
    }
}

private struct EnergyLabelView: View {
    let energy: Double
    let name: String

    var body: some View {
        VStack {
                Text(
                    "\(Text(energy.format()).font(.subheadline).bold()) \(Text("Cals").font(.caption2))",
                    comment: "Energy value with its unit. The placeholders are an amount and the unit \"Cals\"."
                )
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NetEnergyMathView(
        basalEnergy: 1800,
        activeEnergy: 600,
        dietaryEnergy: 1600,
        netEnergy: -800
    )
}
