//
//  EnergyBurnedSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI

struct EnergyBurnedSummaryCell: View {
    let energyBurnedSummary: EnergyBurnedSummary

    var body: some View {
        VStack {
            HStack {
                Text("Activity Level")
                    .bold()
                Spacer()

                Image(systemName: "chevron.up.circle.fill")
                    .foregroundStyle(.green, .background.secondary)
                    .font(.largeTitle)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Basal: \(energyBurnedSummary.averageBasalEnergyBurned, specifier: "%.0f") Cal")
                    Text("Active: \(energyBurnedSummary.averageActiveEnergyBurned, specifier: "%.0f") Cal")
                }
                .font(.headline)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)

                Spacer()
                Text(energyBurnedSummary.activityLevel.name)
                    .font(.title2)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 13)
                .fill(.background)
        }
    }
}

#Preview {
    ScrollView {
        HStack {
            Spacer()
            EnergyBurnedSummaryCell(
                energyBurnedSummary: .init(
                    averageBasalEnergyBurned: 1700,
                    averageActiveEnergyBurned: 661
                )
            )
            Spacer()
        }
    }
    .background {
        Rectangle()
            .fill(.green)
            .ignoresSafeArea()
    }
}
