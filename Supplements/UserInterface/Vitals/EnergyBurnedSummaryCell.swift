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

        HStack {
            VStack(alignment: .leading) {
                Text("Activity Level")
                    .bold()
                    .font(.title3)
                Spacer()

                Group {
                    Text("Basal: \(energyBurnedSummary.averageBasalEnergyBurned, specifier: "%.0f") Cal")
                    Text("Active: \(energyBurnedSummary.averageActiveEnergyBurned, specifier: "%.0f") Cal")
                }
                .font(.headline)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Image(systemName: energyBurnedSummary.isIncreasing ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .foregroundStyle(.green, .background.secondary)
                    .font(.largeTitle)
                    .bold()

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
        VStack {
            EnergyBurnedSummaryCell(
                energyBurnedSummary: .init(
                    averageBasalEnergyBurned: 1700,
                    averageActiveEnergyBurned: 661,
                    lastMonthAverageBasalEnergyBurned: 1700,
                    lastMonthAverageActiveEnergyBurned: 750
                )
            )
        }
        .padding()
    }
    .background {
        Rectangle()
            .fill(.green)
            .ignoresSafeArea()
    }
}
